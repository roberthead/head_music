# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Whether a voice's next note beams to the one before it. ABC beams notes
  # written together and breaks the beam at a space.
  class BeamAdjacency
    def initialize
      reset
    end

    def mark_break
      @break_pending = true
    end

    # True if a break was marked, false if the previous token was also a
    # note, or nil when there is no prior note to beam against.
    def next_break
      flag = if @break_pending
        true
      elsif @last_was_note
        false
      end
      @break_pending = false
      @last_was_note = true
      flag
    end

    # After a rest, bar line, volta, or voice change, the next note must
    # not beam to whatever preceded the boundary.
    def reset
      @last_was_note = false
      @break_pending = false
    end
  end
end
