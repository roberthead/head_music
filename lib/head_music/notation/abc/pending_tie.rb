# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # A tie, "-", waiting for the note it ties the pending note to.
  class PendingTie
    attr_reader :line

    def initialize
      close
    end

    def open?
      @open
    end

    def open(line)
      @open = true
      @line = line
    end

    def close
      @open = false
      @line = nil
    end

    # A tie left open by a non-note terminator can never close, so each
    # terminator rejects it.
    def reject(line)
      return unless open?

      raise ParseError.new("A tie must be followed by a note", line_number: line || @line, snippet: "-")
    end

    def ensure_ties(pending_note, pitches)
      return if pending_note.ties_to?(pitches)

      raise ParseError.new("A tie must connect two notes of the same pitch", line_number: @line, snippet: "-")
    end
  end
end
