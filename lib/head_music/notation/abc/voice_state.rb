# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Per-voice interpretation state and the note-assembly it drives. Accidentals,
  # the deferred note, ties, and volta tracking are all independent between
  # voices, so each voice owns one of these. Beam adjacency and tie bookkeeping
  # are exposed as transitions rather than raw setters, and the parser hands
  # notes and chords here to be buffered, tied, and flushed onto the voice — the
  # behavior that reads and mutates this state lives with the state itself.
  class VoiceState
    # The identity length scale, used wherever no stretching applies.
    ONE = Rational(1)

    # A note or chord whose placing is deferred until we know whether a
    # broken-rhythm mark follows it. The pitches are computed eagerly so
    # bar-line accidental resets cannot corrupt them. `tied_prefix`, when
    # present, is the already-built rhythmic value of everything tied ahead of
    # this note; its own value is appended at flush time.
    #
    # Its slur marks wait with it, in the order written, since its position
    # is not known until it is placed. So do the ends of any tuplet it begins
    # or ends, each at the count of links before it in the tie chain, or nil
    # for the end of the chain so far.
    #
    # Grace notes wait with it too, and a slur opened before them, marked
    # :grace_open, starts on the first of them.
    PendingNote = Data.define(:pitches, :length, :scale, :tied_prefix, :beam_break, :decorations, :slur_marks, :ratio, :tuplet_ends, :graces) do
      def initialize(pitches:, length:, scale:, tied_prefix: nil, beam_break: nil, decorations: [], slur_marks: [], ratio: nil, tuplet_ends: [], graces: [])
        super
      end
    end

    attr_reader :voice, :pitch_builder, :tie_line
    attr_accessor :pending_note, :awaiting_scale, :broken_line,
      :active_passes, :volta_start_bar

    def initialize(voice, pitch_builder, duration_resolver = nil)
      @voice = voice
      @pitch_builder = pitch_builder
      @duration_resolver = duration_resolver
      @beam_break_pending = false
      @beam_last_was_note = false
      @tie_open = false
      @decorations = PendingDecorations.new(voice)
      @slur_opens = 0
      @grace_slur_opens = 0
      @graces = []
      @open_slurs = []
      @invisible_rests = []
      @tuplets = TupletGrouping.new(voice)
    end

    delegate :decorate, :reject_dangling_decorations, :take_navigation, :add_hairpins, to: :@decorations

    # "(" opens a slur on the next note, chord, or rest.
    def open_slur
      @slur_opens += 1
    end

    # Grace notes wait for the next note or chord, and a slur opened before
    # them starts on the first of them. Inside an open tie, where the next
    # note is a later link, they are dropped.
    def add_graces(graces)
      return if tie_open? || graces.empty?

      @graces.concat(graces)
      @grace_slur_opens += @slur_opens
      @slur_opens = 0
    end

    # A rest, bar line, or the end of the voice drops the grace notes waiting
    # for a note, and a slur opened before them starts on what comes next.
    def drop_graces
      @graces = []
      @slur_opens += @grace_slur_opens
      @grace_slur_opens = 0
    end

    # ")" closes the latest open slur on the note just written. Slurs pair by
    # nesting, as ABC reads them, so "(CD(E)FG)" is one slur from C to G, and
    # the slur on E alone, which spans nothing, is dropped. A close on a tied
    # note's first link comes before an open on its next, so "(AB-)(BC)" is
    # two slurs.
    def close_slur
      if pending_note
        self.pending_note = pending_note.with(slur_marks: pending_note.slur_marks + [:close])
      elsif voice.last_voice_event
        apply_slurs(voice.last_voice_event, [:close])
      end
    end

    # "(p:q:r" puts the ratio on the next r notes, chords, and rests.
    def open_tuplet(marker, line)
      @tuplets.open(marker, line)
    end

    def end_tuplets
      @tuplets.close
    end

    # Counted from where the last note ends rather than where it starts: a
    # note tied across a bar line is still pending when the repeat tagger
    # asks, and a note longer than its bar has crossed one already.
    def completed_bar_number
      return unless pending_note || voice.last_voice_event || @invisible_rests.any?

      finish = cursor
      bar_start?(finish) ? finish.bar_number - 1 : finish.bar_number
    end

    def entered_bar_number
      cursor.bar_number
    end

    # Where the voice's time has reached, which runs ahead of its voice
    # events while invisible rests wait for music to follow them.
    def cursor
      pending_note ? pending_end_position : music_end
    end

    # An invisible rest becomes a rest only once music follows it, so one
    # that ends the voice adds no event. In an overlay it only moves the
    # overlay's cursor.
    def skip(length)
      @decorations.place_at(mark_position)
      if overlay?
        @overlay_cursor += @duration_resolver.rhythmic_value(length)
      else
        ratio, ends = @tuplets.count
        from = music_end
        @invisible_rests << @duration_resolver.rhythmic_value(length, tuplet: ratio)
        @tuplets.mark_ends(ends, from, music_end)
      end
    end

    # A spacer takes no time, and holds a level where it stands.
    def space
      @decorations.place_at(mark_position)
    end

    def settle_hairpins
      @decorations.settle_hairpins(mark_position)
    end

    # The bar a voice overlay starts over is the one the last bar line opened.
    def cross_bar_line(line = nil)
      end_overlay(line)
      @bar_start = cursor
    end

    # Invisible rests left in the bar where the music ends hold only time for
    # a level there. Once they reach a later bar, that bar is part of the
    # music, and they are rests.
    def end_invisible_rests
      return if @invisible_rests.empty?

      music_stop = voice.next_position
      barline = bar_start?(music_stop) ? music_stop : HeadMusic::Content::Position.new(voice.flow, music_stop.bar_number + 1, 1, 0)
      return unless music_end > barline

      @invisible_rests.each { |rest_value| voice.place(voice.next_position, rest_value) }
      @invisible_rests.clear
      @tuplets.group_closed
    end

    def start_overlay
      @overlay_cursor = @bar_start || HeadMusic::Content::Position.new(voice.flow, 1, 1, 0)
    end

    def end_overlay(line = nil)
      if @overlay_cursor && @overlay_cursor > cursor
        raise ParseError.new("A voice overlay must not run past its bar's music", line_number: line, snippet: "&")
      end

      @overlay_cursor = nil
    end

    def overlay?
      !@overlay_cursor.nil?
    end

    # Records an explicit beam break; the next note consumes it.
    def mark_beam_break
      @beam_break_pending = true
    end

    # The beam-break flag for the note now beginning: true if a break was
    # marked, false if the previous token was also a note (so they beam
    # together), or nil when there is no prior note to beam against.
    # Consumes the pending break and records that a note is now current.
    def next_beam_break
      flag = if @beam_break_pending
        true
      elsif @beam_last_was_note
        false
      end
      @beam_break_pending = false
      @beam_last_was_note = true
      flag
    end

    # After a rest, bar line, volta, or voice change, the next note must
    # not beam to whatever preceded the boundary.
    def reset_beam_adjacency
      @beam_last_was_note = false
      @beam_break_pending = false
    end

    def tie_open?
      @tie_open
    end

    def open_tie(line)
      @tie_open = true
      @tie_line = line
    end

    def close_tie
      @tie_open = false
      @tie_line = nil
    end

    # A tie left open by a non-note terminator can never close, so each
    # terminator rejects it.
    def reject_open_tie(line)
      return unless tie_open?

      raise ParseError.new("A tie must be followed by a note", line_number: line || tie_line, snippet: "-")
    end

    # A tie or broken rhythm needs a note before it that is not itself
    # waiting on a broken rhythm's right side.
    def after_note?
      pending_note && !awaiting_scale
    end

    def break_rhythm(left_scale, right_scale, line)
      self.pending_note = pending_note.with(scale: pending_note.scale * left_scale)
      self.awaiting_scale = right_scale
      self.broken_line = line
    end

    def ensure_not_awaiting_note(line)
      return unless awaiting_scale

      raise ParseError.new("Broken rhythm must be followed by a note", line_number: line || broken_line)
    end

    # Buffers a note or chord as the pending note, flushing whatever was
    # pending first. A broken-rhythm scale awaiting its right note, and any
    # per-chord inner scale, fold into the buffered length. When a tie is
    # open the arriving note instead extends the pending tie chain.
    def defer_voice_event(pitches, length, inner_scale = ONE)
      scale = (awaiting_scale || ONE) * inner_scale
      self.awaiting_scale = nil
      decorations = @decorations.take
      ratio, ends = @tuplets.count
      return tie_onto_pending(pitches, length, scale, decorations, ratio, ends) if tie_open?

      flush_pending_note
      self.pending_note = PendingNote.new(
        pitches: pitches, length: length, scale: scale, beam_break: next_beam_break,
        decorations: decorations, slur_marks: take_grace_slur_opens + take_slur_opens, ratio: ratio, tuplet_ends: ends,
        graces: take_graces
      )
    end

    # Places the pending note onto the voice, if any, carrying its authored
    # beam break onto the voice event.
    def flush_pending_note
      pending = pending_note
      return unless pending

      self.pending_note = nil
      voice_event = place_next(pending_rhythmic_value(pending), pending.pitches)
      voice_event.beam_break_before = pending.beam_break
      add_grace_notes(voice_event, pending.graces)
      @decorations.apply(voice_event, pending.decorations)
      apply_slurs(voice_event, pending.slur_marks)
      @tuplets.place_ends(voice_event, pending.tuplet_ends, pending.tied_prefix)
    end

    # Places a note, chord, or rest (nil pitches) directly onto the voice,
    # bypassing the pending-note buffer, with the decorations waiting for it.
    def place(length, pitches, scale: ONE)
      ratio, ends = @tuplets.count
      voice_event = place_next(@duration_resolver.rhythmic_value(length, scale: scale, tuplet: ratio), pitches)
      @decorations.apply(voice_event, @decorations.take)
      apply_slurs(voice_event, take_slur_opens)
      @tuplets.place_ends(voice_event, ends)
      voice_event
    end

    private

    def take_slur_opens
      opens = [:open] * @slur_opens
      @slur_opens = 0
      opens
    end

    def take_grace_slur_opens
      opens = [:grace_open] * @grace_slur_opens
      @grace_slur_opens = 0
      opens
    end

    def take_graces
      graces = @graces
      @graces = []
      graces
    end

    def add_grace_notes(voice_event, graces)
      graces.each do |grace|
        voice_event.add_grace_note(
          grace.sounds, grace.rhythmic_value, slashed: grace.slashed?, tied: grace.tied?, articulations: grace.articulations
        )
      end
    end

    def apply_slurs(voice_event, slur_marks)
      position = voice_event.position
      slur_marks.each do |mark|
        if mark == :close
          close_slur_at(position)
        else
          @open_slurs << [position, mark == :grace_open]
        end
      end
    end

    # A slur the voice refuses, such as one ending on a rest, is dropped.
    def close_slur_at(position)
      from, from_grace = @open_slurs.pop
      voice.add_span(:slur, from: from, to: position, from_grace: from_grace) if spans?(from, position, from_grace)
    rescue ArgumentError
      nil
    end

    # A slur from grace notes may end on their own main note.
    def spans?(from, to, from_grace)
      return false unless from

      from < to || (from_grace && from == to)
    end

    def place_next(rhythmic_value, pitches)
      @invisible_rests.each { |rest_value| voice.place(voice.next_position, rest_value) }
      @invisible_rests.clear
      voice.place(voice.next_position, rhythmic_value, pitches)
    end

    def mark_position
      @overlay_cursor || cursor
    end

    def music_end
      @invisible_rests.reduce(voice.next_position) { |position, rest_value| position + rest_value }
    end

    # Closes an open tie: the pending note becomes the new note's tied prefix,
    # so the pair (and any longer chain) resolves to a single voice event whose
    # rhythmic value carries the author's chosen split.
    #
    # The tied note's markings join the whole event's, but a level or hairpin
    # mark written on it takes effect where it is written, partway through the
    # event.
    def tie_onto_pending(pitches, length, scale, decorations, ratio, tuplet_ends)
      pending = pending_note
      prefix = pending_rhythmic_value(pending)
      marks, markings = decorations.partition(&:positional?)
      marks.each { |decoration| @decorations.place_mark(music_end + prefix, decoration) }
      close_tie
      drop_graces
      self.pending_note = PendingNote.new(
        pitches: tied_pitches(pending, pitches), length: length, scale: scale, tied_prefix: prefix,
        beam_break: pending.beam_break, decorations: pending.decorations + markings,
        slur_marks: pending.slur_marks + take_slur_opens,
        ratio: ratio, tuplet_ends: @tuplets.fix_ends(pending.tuplet_ends, pending.tied_prefix, prefix) + tuplet_ends, graces: pending.graces
      )
    end

    # A tie carries its accidental across the bar line, where the key
    # signature would otherwise respell the note, so the same letters in the
    # same octaves are the same pitches.
    def tied_pitches(pending, pitches)
      return pending.pitches if same_letters?(pending.pitches, pitches)

      raise ParseError.new(
        "A tie must connect two notes of the same pitch",
        line_number: tie_line, snippet: "-"
      )
    end

    def same_letters?(pitches, other_pitches)
      letters_and_registers(pitches) == letters_and_registers(other_pitches)
    end

    def letters_and_registers(pitches)
      pitches.map { |pitch| [pitch.letter_name.to_s, pitch.register] }.sort
    end

    def pending_end_position
      music_end + pending_rhythmic_value(pending_note)
    end

    def bar_start?(position)
      position.to_a.drop(1) == [1, 0, 0]
    end

    # A pending note's own value, with any tied prefix appended ahead of
    # it so the whole tie chain renders as one sounding note.
    def pending_rhythmic_value(pending)
      own = @duration_resolver.rhythmic_value(pending.length, scale: pending.scale, tuplet: pending.ratio)
      prefix = pending.tied_prefix
      prefix ? prefix.append_tied(own) : own
    end
  end
end
