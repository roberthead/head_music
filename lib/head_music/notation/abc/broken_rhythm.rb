# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # A broken-rhythm mark, ">" or "<", between two notes of a voice: it
  # lengthens one by half and halves the other. The left note is waiting
  # already when the mark is read; the right note's scale waits for it.
  class BrokenRhythm
    # The mark's side gets the dot (x 3/2) and the other side is halved.
    SCALES = {
      :> => [Rational(3, 2), Rational(1, 2)],
      :< => [Rational(1, 2), Rational(3, 2)]
    }.freeze

    def awaiting_note?
      !@right_scale.nil?
    end

    # The left note, scaled. It cannot be a right note still awaited.
    def break(left_note, direction, line)
      if left_note.nil? || awaiting_note?
        raise ParseError.new("Broken rhythm must appear between two notes", line_number: line, snippet: direction.to_s)
      end

      left_scale, @right_scale = SCALES.fetch(direction)
      @line = line
      left_note.scaled(left_scale)
    end

    # The arriving note's scale, which is one unless a mark awaits it.
    def take_scale
      scale = @right_scale || Rational(1)
      @right_scale = nil
      scale
    end

    def ensure_not_awaiting_note(line)
      return unless awaiting_note?

      raise ParseError.new("Broken rhythm must be followed by a note", line_number: line || @line)
    end
  end
end
