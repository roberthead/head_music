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

    # A note or chord whose placement is deferred until we know whether a
    # broken-rhythm mark follows it. The pitches are computed eagerly so
    # bar-line accidental resets cannot corrupt them. `tied_prefix`, when
    # present, is the already-built rhythmic value of everything tied ahead of
    # this note; its own value is appended at flush time.
    PendingNote = Data.define(:pitches, :length, :scale, :tied_prefix, :beam_break) do
      def initialize(pitches:, length:, scale:, tied_prefix: nil, beam_break: nil)
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
    end

    def completed_bar_number
      voice.last_placement&.position&.bar_number
    end

    def entered_bar_number
      voice.next_position.bar_number
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
    def defer_placement(pitches, length, inner_scale = ONE)
      scale = (awaiting_scale || ONE) * inner_scale
      self.awaiting_scale = nil
      return tie_onto_pending(pitches, length, scale) if tie_open?

      flush_pending_note
      self.pending_note = PendingNote.new(
        pitches: pitches, length: length, scale: scale, beam_break: next_beam_break
      )
    end

    # Places the pending note onto the voice, if any, carrying its authored
    # beam break onto the placement.
    def flush_pending_note
      pending = pending_note
      return unless pending

      self.pending_note = nil
      placement = voice.place(voice.next_position, pending_rhythmic_value(pending), pending.pitches)
      placement.beam_break_before = pending.beam_break
    end

    # Places a note, chord, or rest (nil pitches) directly onto the voice,
    # bypassing the pending-note buffer.
    def place(length, pitches, scale: ONE)
      rhythmic_value = @duration_resolver.rhythmic_value(length, scale: scale)
      voice.place(voice.next_position, rhythmic_value, pitches)
    end

    private

    # Closes an open tie: the pending note becomes the new note's tied prefix,
    # so the pair (and any longer chain) resolves to a single placement whose
    # rhythmic value carries the author's chosen split.
    def tie_onto_pending(pitches, length, scale)
      pending = pending_note
      ensure_tie_pitches_match(pending, pitches)
      prefix = pending_rhythmic_value(pending)
      close_tie
      self.pending_note = PendingNote.new(
        pitches: pitches, length: length, scale: scale, tied_prefix: prefix,
        beam_break: pending.beam_break
      )
    end

    def ensure_tie_pitches_match(pending, pitches)
      return if pending.pitches.sort == pitches.sort

      raise ParseError.new(
        "A tie must connect two notes of the same pitch",
        line_number: tie_line, snippet: "-"
      )
    end

    # A pending note's own value, with any tied prefix appended ahead of
    # it so the whole tie chain renders as one sounding note.
    def pending_rhythmic_value(pending)
      own = @duration_resolver.rhythmic_value(pending.length, scale: pending.scale)
      prefix = pending.tied_prefix
      prefix ? append_tied(prefix, own) : own
    end

    # Attaches `tail` at the deep end of `head`'s tied chain, rebuilding
    # each link (RhythmicValue exposes no setter) so a chain like
    # "half tied to eighth" gains a further "tied to quarter".
    def append_tied(head, tail)
      tied = head.tied_value
      inner = tied ? append_tied(tied, tail) : tail
      HeadMusic::Rudiment::RhythmicValue.new(head.unit, dots: head.dots, tied_value: inner)
    end
  end
end
