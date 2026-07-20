# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Per-voice interpretation state for the ABC Parser. Accidentals, the
  # deferred note, and volta tracking are all independent between voices.
  # Beam adjacency and tie bookkeeping are exposed as transitions rather than
  # raw setters, so the parser drives the state machine without reaching into
  # its flags.
  class VoiceState
    attr_reader :voice, :pitch_builder, :tie_line
    attr_accessor :pending_note, :awaiting_scale, :broken_line,
      :active_passes, :volta_start_bar

    def initialize(voice, pitch_builder)
      @voice = voice
      @pitch_builder = pitch_builder
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
  end
end
