# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Converts a kern pitch (letters and accidentals, as in "cc#" or "GG-")
  # into a pitch.
  #
  # Case and repetition give the register: c is middle C, cc the octave
  # above, C the octave below, and CC the octave below that.
  module PitchReader
    FRAGMENTS_BY_ACCIDENTAL = {"" => "", "n" => "", "#" => "#", "##" => "x", "-" => "b", "--" => "bb"}.freeze

    module_function

    def pitch(letters, accidental, line_number: nil, snippet: nil)
      letter = letters[0]
      register = register_of(letter, letters.length)
      fragment = FRAGMENTS_BY_ACCIDENTAL.fetch(accidental.to_s) do
        raise ParseError.new(%(Unrecognized accidental "#{accidental}"), line_number: line_number, snippet: snippet)
      end
      # Register.get answers an unreachable number with its default rather
      # than nil, which would silently move the pitch.
      unless HeadMusic::Rudiment::Register.from_number(register)
        raise ParseError.new(%(Pitch "#{letters}#{accidental}" is out of range), line_number: line_number, snippet: snippet)
      end

      HeadMusic::Rudiment::Pitch.from_name("#{letter.upcase}#{fragment}#{register}")
    end

    def register_of(letter, count)
      (letter == letter.downcase) ? 3 + count : 4 - count
    end
  end
end
