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
    # is not known until it is placed.
    PendingNote = Data.define(:pitches, :length, :scale, :tied_prefix, :beam_break, :decorations, :slur_marks) do
      def initialize(pitches:, length:, scale:, tied_prefix: nil, beam_break: nil, decorations: [], slur_marks: [])
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
      @open_slurs = []
    end

    delegate :decorate, :reject_dangling_decorations, to: :@decorations

    # "(" opens a slur on the next note, chord, or rest.
    def open_slur
      @slur_opens += 1
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

    # Counted from where the last note ends rather than where it starts: a
    # note tied across a bar line is still pending when the repeat tagger
    # asks, and a note longer than its bar has crossed one already.
    def completed_bar_number
      finish = pending_note ? pending_end_position : voice.last_voice_event&.next_position
      return unless finish

      bar_start?(finish) ? finish.bar_number - 1 : finish.bar_number
    end

    def entered_bar_number
      (pending_note ? pending_end_position : voice.next_position).bar_number
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

    # Buffers a note or chord as the pending note, flushing whatever was
    # pending first. A broken-rhythm scale awaiting its right note, and any
    # per-chord inner scale, fold into the buffered length. When a tie is
    # open the arriving note instead extends the pending tie chain.
    def defer_voice_event(pitches, length, inner_scale = ONE)
      scale = (awaiting_scale || ONE) * inner_scale
      self.awaiting_scale = nil
      decorations = @decorations.take
      return tie_onto_pending(pitches, length, scale, decorations) if tie_open?

      flush_pending_note
      self.pending_note = PendingNote.new(
        pitches: pitches, length: length, scale: scale, beam_break: next_beam_break,
        decorations: decorations, slur_marks: take_slur_opens
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
      @decorations.apply(voice_event, pending.decorations)
      apply_slurs(voice_event, pending.slur_marks)
    end

    # Places a note, chord, or rest (nil pitches) directly onto the voice,
    # bypassing the pending-note buffer, with the decorations waiting for it.
    def place(length, pitches, scale: ONE)
      voice_event = place_next(@duration_resolver.rhythmic_value(length, scale: scale), pitches)
      @decorations.apply(voice_event, @decorations.take)
      apply_slurs(voice_event, take_slur_opens)
      voice_event
    end

    private

    def take_slur_opens
      opens = [:open] * @slur_opens
      @slur_opens = 0
      opens
    end

    def apply_slurs(voice_event, slur_marks)
      position = voice_event.position
      slur_marks.each { |mark| (mark == :open) ? @open_slurs << position : close_slur_at(position) }
    end

    # A slur the voice refuses, such as one ending on a rest, is dropped.
    def close_slur_at(position)
      from = @open_slurs.pop
      voice.add_span(:slur, from: from, to: position) if from && from < position
    rescue ArgumentError
      nil
    end

    def place_next(rhythmic_value, pitches)
      voice.place(voice.next_position, rhythmic_value, pitches)
    end

    # Closes an open tie: the pending note becomes the new note's tied prefix,
    # so the pair (and any longer chain) resolves to a single voice event whose
    # rhythmic value carries the author's chosen split.
    #
    # The tied note's markings join the whole event's, but a level written on
    # it takes effect where it is written, partway through the event.
    def tie_onto_pending(pitches, length, scale, decorations)
      pending = pending_note
      prefix = pending_rhythmic_value(pending)
      levels, markings = decorations.partition(&:level?)
      levels.each { |decoration| @decorations.place_level(voice.next_position + prefix, decoration) }
      close_tie
      self.pending_note = PendingNote.new(
        pitches: tied_pitches(pending, pitches), length: length, scale: scale, tied_prefix: prefix,
        beam_break: pending.beam_break, decorations: pending.decorations + markings,
        slur_marks: pending.slur_marks + take_slur_opens
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
      voice.next_position + pending_rhythmic_value(pending_note)
    end

    def bar_start?(position)
      position.to_a.drop(1) == [1, 0, 0]
    end

    # A pending note's own value, with any tied prefix appended ahead of
    # it so the whole tie chain renders as one sounding note.
    def pending_rhythmic_value(pending)
      own = @duration_resolver.rhythmic_value(pending.length, scale: pending.scale)
      prefix = pending.tied_prefix
      prefix ? prefix.append_tied(own) : own
    end
  end
end
