# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Per-voice interpretation state and the note-assembly it drives. Accidentals,
  # the deferred note, ties, and volta tracking are all independent between
  # voices, so each voice owns one of these. The parser hands notes and chords
  # here to be buffered, tied, and flushed onto the voice, and says where a run
  # of notes ends or pauses.
  class VoiceState
    # The identity length scale, used wherever no stretching applies.
    ONE = Rational(1)

    attr_reader :voice, :pitch_builder, :beams
    attr_accessor :pending_note, :active_passes, :volta_start_bar

    def initialize(voice, pitch_builder, duration_resolver = nil, fermata_marks = HeadMusic::Notation::FermataMarks.new)
      @voice = voice
      @pitch_builder = pitch_builder
      @duration_resolver = duration_resolver
      @beams = BeamAdjacency.new
      @broken_rhythm = BrokenRhythm.new
      @tie = PendingTie.new
      @decorations = PendingDecorations.new(voice, fermata_marks)
      @slurs = PendingSlurs.new(voice)
      @graces = PendingGraces.new(@slurs)
      @invisible_rests = InvisibleRests.new(voice)
      @tuplets = TupletGrouping.new(voice)
      @overlay = VoiceOverlay.new(voice)
    end

    delegate :music_end, to: :@invisible_rests
    delegate :open?, :line, to: :@tie, prefix: :tie
    delegate :ensure_not_awaiting_note, to: :@broken_rhythm
    delegate :decorate, :take_navigation, :add_hairpins, to: :@decorations

    # "(" opens a slur on the next note, chord, or rest.
    def open_slur
      @slurs.open
    end

    # Grace notes wait for the next note or chord, and a slur opened before
    # them starts on the first of them. Inside an open tie, where the next
    # note is a later link, they are dropped. A level or hairpin mark on a
    # grace note waits for its main note.
    def add_graces(graces, decorations)
      decorations.each { |decoration| decorate(decoration) }
      @graces.add(graces) unless tie_open?
    end

    # ")" closes the latest open slur on the note just written. Slurs pair by
    # nesting, as ABC reads them, so "(CD(E)FG)" is one slur from C to G, and
    # the slur on E alone, which spans nothing, is dropped. A close on a tied
    # note's first link comes before an open on its next, so "(AB-)(BC)" is
    # two slurs.
    def close_slur
      return self.pending_note = pending_note.closing_slur if pending_note

      last_voice_event = voice.last_voice_event
      @slurs.apply(last_voice_event, [:close]) if last_voice_event
    end

    # "(p:q:r" puts the ratio on the next r notes, chords, and rests.
    def open_tuplet(marker, line)
      @tuplets.open(marker, line)
    end

    # Counted from where the last note ends rather than where it starts: a
    # note tied across a bar line is still pending when the repeat tagger
    # asks, and a note longer than its bar has crossed one already.
    def completed_bar_number
      cursor.ending_bar_number if pending_note || voice.last_voice_event || @invisible_rests.any?
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
        @tuplets.mark_ends(ends, *@invisible_rests.add(@duration_resolver.rhythmic_value(length, tuplet: ratio)))
      end
    end

    # A spacer takes no time, and holds a level where it stands.
    def space(line)
      ensure_not_awaiting_note(line)
      @decorations.place_at(mark_position)
    end

    def settle_hairpins
      @decorations.settle_hairpins(mark_position)
    end

    # A rest, a voice change, or the end of the tune ends a run of notes:
    # nothing after it can complete a broken rhythm or close a tie.
    def end_notes(line)
      interrupt_notes(line)
      reject_open_tie(line)
      flush_pending_note
    end

    # A bar line, volta, or overlay only pauses one: a tied note stays
    # pending across it and closes on the next note.
    def pause_notes(line)
      interrupt_notes(line)
      settle_and_reject_decorations
      flush_pending_note unless tie_open?
    end

    def cross_bar_line(line = nil)
      pause_notes(line)
      end_overlay(line)
      @overlay.bar_line(cursor)
    end

    # Nothing further in the voice can take a decoration either.
    def end_voice(line)
      end_notes(line)
      settle_and_reject_decorations
      end_overlay(line)
      end_invisible_rests
      @tuplets.close
    end

    # "&" starts the bar over, so the overlay's invisible rests can place
    # levels where no note of the bar starts. A note tied across the bar line
    # stays pending.
    def start_overlay(line)
      pause_notes(line)
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

    # A tie (`-`) after a note or chord fuses it to the next note of the
    # same pitch. The left note stays pending; the tie is only closed once
    # its right note arrives.
    def open_tie(line)
      raise ParseError.new("A tie must follow a note", line_number: line, snippet: "-") unless after_note?

      reject_dangling_decorations
      @tie.open(line)
    end

    def close_tie
      @tie.close
    end

    # A fermata with no note after it, as before a bar line, marks the note
    # before it.
    def reject_dangling_decorations
      fermatas = @decorations.reject_dangling_decorations
      return if fermatas.empty?

      return self.pending_note = pending_note.decorated(fermatas) if pending_note

      @decorations.hold_last
    end

    def reject_open_tie(line)
      @tie.reject(line)
    end

    # A tie needs a note before it that is not itself waiting on a broken
    # rhythm's right side.
    def after_note?
      pending_note && !@broken_rhythm.awaiting_note?
    end

    def break_rhythm(direction, line)
      reject_open_tie(line)
      reject_dangling_decorations
      self.pending_note = @broken_rhythm.break(pending_note, direction, line)
    end

    # Buffers a note or chord as the pending note, flushing whatever was
    # pending first. A broken-rhythm scale awaiting its right note, and any
    # per-chord inner scale, fold into the buffered length. When a tie is
    # open the arriving note instead extends the pending tie chain.
    def defer_voice_event(pitches, length, inner_scale = ONE)
      tied = tie_open?
      @graces.drop if tied
      note = arriving_note(pitches, length, inner_scale)
      return tie_onto_pending(note) if tied

      flush_pending_note
      self.pending_note = note.with(beam_break: @beams.next_break)
    end

    # Places the pending note onto the voice, if any, carrying its authored
    # beam break onto the voice event.
    def flush_pending_note
      pending = pending_note
      return unless pending

      self.pending_note = nil
      voice_event = place_next(pending)
      pending.carry_onto(voice_event)
      apply_marks(voice_event, pending)
    end

    # Where a mark written now stands: in an overlay, at the overlay's cursor.
    def mark_position
      @overlay.cursor || cursor
    end

    # Places a note, chord, or rest (nil pitches) directly onto the voice,
    # bypassing the pending-note buffer, with the decorations waiting for it.
    def place(length, pitches, scale: ONE)
      note = written_note(pitches, length, scale)
      place_next(note).tap { |voice_event| apply_marks(voice_event, note) }
    end

    private

    # A rest, bar line, or the end of the voice drops the grace notes waiting
    # for a note.
    def interrupt_notes(line)
      @graces.drop
      ensure_not_awaiting_note(line)
      @beams.reset
    end

    def settle_and_reject_decorations
      settle_hairpins
      reject_dangling_decorations
    end

    # Invisible rests left in the bar where the music ends hold only time for
    # a level there.
    def end_invisible_rests
      return unless @invisible_rests.past_last_bar?

      @invisible_rests.place
      @tuplets.group_closed
    end

    def place_next(note)
      @invisible_rests.place
      voice.place(voice.next_position, note.rhythmic_value(@duration_resolver), note.pitches)
    end

    def apply_marks(voice_event, note)
      @decorations.apply(voice_event, note.decorations)
      @slurs.apply(voice_event, note.slur_marks)
      @tuplets.place_ends(voice_event, note.tuplet_ends, note.tied_prefix)
    end

    def arriving_note(pitches, length, inner_scale)
      written_note(pitches, length, @broken_rhythm.take_scale * inner_scale, graces: @graces.take)
    end

    # A note, chord, or rest with the tuplet count, decorations, and slur
    # marks waiting for it.
    def written_note(pitches, length, scale, graces: [])
      ratio, ends = @tuplets.count
      PendingNote.new(
        pitches: pitches, length: length, scale: scale, ratio: ratio, tuplet_ends: ends,
        decorations: @decorations.take, slur_marks: @slurs.take, graces: graces
      )
    end

    # Closes an open tie: the pending note becomes the new link's tied prefix,
    # so the pair (and any longer chain) resolves to a single voice event whose
    # rhythmic value carries the author's chosen split.
    #
    # A mark written on the tied link takes effect where it is written,
    # partway through the event.
    def tie_onto_pending(link)
      pending = pending_note
      @tie.ensure_ties(pending, link.pitches)
      prefix = pending.rhythmic_value(@duration_resolver)
      markings = @decorations.mark_link(pending_end_position, link.decorations)
      close_tie
      fixed_ends = @tuplets.fix_ends(pending.tuplet_ends, pending.tied_prefix, prefix)
      self.pending_note = pending.tied_to(link.with(decorations: markings), prefix, fixed_ends)
    end

    def pending_end_position
      music_end + pending_note.rhythmic_value(@duration_resolver)
    end
  end
end
