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

    # The left note's scale.
    def break(direction, line)
      left_scale, @right_scale = SCALES.fetch(direction)
      @line = line
      left_scale
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
