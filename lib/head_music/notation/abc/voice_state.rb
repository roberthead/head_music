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

    attr_reader :voice, :pitch_builder, :tie_line, :beams
    attr_accessor :pending_note, :active_passes, :volta_start_bar

    def initialize(voice, pitch_builder, duration_resolver = nil)
      @voice = voice
      @pitch_builder = pitch_builder
      @duration_resolver = duration_resolver
      @beams = BeamAdjacency.new
      @broken_rhythm = BrokenRhythm.new
      @tie_open = false
      @decorations = PendingDecorations.new(voice)
      @slurs = PendingSlurs.new(voice)
      @graces = []
      @invisible_rests = InvisibleRests.new(voice)
      @tuplets = TupletGrouping.new(voice)
      @overlay = VoiceOverlay.new(voice)
    end

    delegate :music_end, to: :@invisible_rests
    delegate :ensure_not_awaiting_note, to: :@broken_rhythm
    delegate :decorate, :reject_dangling_decorations, :take_navigation, :add_hairpins, to: :@decorations

    # "(" opens a slur on the next note, chord, or rest.
    def open_slur
      @slurs.open
    end

    # Grace notes wait for the next note or chord, and a slur opened before
    # them starts on the first of them. Inside an open tie, where the next
    # note is a later link, they are dropped.
    def add_graces(graces)
      return if tie_open? || graces.empty?

      @graces.concat(graces)
      @slurs.start_on_graces
    end

    # A rest, bar line, or the end of the voice drops the grace notes waiting
    # for a note, and a slur opened before them starts on what comes next.
    def drop_graces
      @graces = []
      @slurs.start_after_graces
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
        @slurs.apply(voice.last_voice_event, [:close])
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
      ending_bar_number(cursor) if pending_note || voice.last_voice_event || @invisible_rests.any?
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
        @overlay.advance(@duration_resolver.rhythmic_value(length))
      else
        ratio, ends = @tuplets.count
        from = music_end
        @invisible_rests.add @duration_resolver.rhythmic_value(length, tuplet: ratio)
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

    def cross_bar_line(line = nil)
      end_overlay(line)
      @overlay.bar_line(cursor)
    end

    # Invisible rests left in the bar where the music ends hold only time for
    # a level there. Once they reach a later bar, that bar is part of the
    # music, and they are rests.
    def end_invisible_rests
      return unless ending_bar_number(music_end) > ending_bar_number(voice.next_position)

      @invisible_rests.place
      @tuplets.group_closed
    end

    def start_overlay
      @overlay.start
    end

    def end_overlay(line = nil)
      @overlay.finish(cursor, line)
    end

    def overlay?
      @overlay.active?
    end

    def reject_overlay_music(token)
      @overlay.reject_music(token)
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
      pending_note && !@broken_rhythm.awaiting_note?
    end

    def break_rhythm(direction, line)
      unless after_note?
        raise ParseError.new("Broken rhythm must appear between two notes", line_number: line, snippet: direction.to_s)
      end

      self.pending_note = pending_note.with(scale: pending_note.scale * @broken_rhythm.break(direction, line))
    end

    # Buffers a note or chord as the pending note, flushing whatever was
    # pending first. A broken-rhythm scale awaiting its right note, and any
    # per-chord inner scale, fold into the buffered length. When a tie is
    # open the arriving note instead extends the pending tie chain.
    def defer_voice_event(pitches, length, inner_scale = ONE)
      tied = tie_open?
      drop_graces if tied
      note = arriving_note(pitches, length, inner_scale, beam_break: tied ? nil : @beams.next_break)
      return tie_onto_pending(note) if tied

      flush_pending_note
      self.pending_note = note
    end

    # Places the pending note onto the voice, if any, carrying its authored
    # beam break onto the voice event.
    def flush_pending_note
      pending = pending_note
      return unless pending

      self.pending_note = nil
      voice_event = place_next(pending.rhythmic_value(@duration_resolver), pending.pitches)
      voice_event.beam_break_before = pending.beam_break
      pending.add_graces_to(voice_event)
      @decorations.apply(voice_event, pending.decorations)
      @slurs.apply(voice_event, pending.slur_marks)
      @tuplets.place_ends(voice_event, pending.tuplet_ends, pending.tied_prefix)
    end

    # Places a note, chord, or rest (nil pitches) directly onto the voice,
    # bypassing the pending-note buffer, with the decorations waiting for it.
    def place(length, pitches, scale: ONE)
      ratio, ends = @tuplets.count
      voice_event = place_next(@duration_resolver.rhythmic_value(length, scale: scale, tuplet: ratio), pitches)
      @decorations.apply(voice_event, @decorations.take)
      @slurs.apply(voice_event, @slurs.take)
      @tuplets.place_ends(voice_event, ends)
      voice_event
    end

    private

    def place_next(rhythmic_value, pitches)
      @invisible_rests.place
      voice.place(voice.next_position, rhythmic_value, pitches)
    end

    def mark_position
      @overlay.cursor || cursor
    end

    def arriving_note(pitches, length, inner_scale, beam_break:)
      scale = @broken_rhythm.take_scale * inner_scale
      decorations = @decorations.take
      ratio, ends = @tuplets.count
      graces = @graces
      @graces = []
      PendingNote.new(
        pitches: pitches, length: length, scale: scale, beam_break: beam_break, decorations: decorations,
        slur_marks: @slurs.take, ratio: ratio, tuplet_ends: ends, graces: graces
      )
    end

    # Closes an open tie: the pending note becomes the new link's tied prefix,
    # so the pair (and any longer chain) resolves to a single voice event whose
    # rhythmic value carries the author's chosen split.
    #
    # The tied link's markings join the whole event's, but a level or hairpin
    # mark written on it takes effect where it is written, partway through the
    # event.
    def tie_onto_pending(link)
      pending = pending_note
      prefix = pending.rhythmic_value(@duration_resolver)
      marks, markings = link.decorations.partition(&:positional?)
      marks.each { |decoration| @decorations.place_mark(music_end + prefix, decoration) }
      close_tie
      unless pending.ties_to?(link.pitches)
        raise ParseError.new("A tie must connect two notes of the same pitch", line_number: tie_line, snippet: "-")
      end

      fixed_ends = @tuplets.fix_ends(pending.tuplet_ends, pending.tied_prefix, prefix)
      self.pending_note = pending.tied_to(link.with(decorations: markings), prefix, fixed_ends)
    end

    def pending_end_position
      music_end + pending_note.rhythmic_value(@duration_resolver)
    end

    # The bar where music ending at the position ends: the one before, at a
    # bar line.
    def ending_bar_number(position)
      bar_number = position.bar_number
      (position.to_a.drop(1) == [1, 0, 0]) ? bar_number - 1 : bar_number
    end
  end
end
