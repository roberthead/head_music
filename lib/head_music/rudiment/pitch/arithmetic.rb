class HeadMusic::Rudiment::Pitch
  # What it means to add to or subtract from a pitch depends on what the other
  # operand is: an interval moves the pitch, a bare number moves it by that many
  # semitones, and subtracting another pitch measures the distance between the
  # two. Every branch reads the operand rather than the pitch, so the dispatch
  # lives here with both in hand rather than on Pitch.
  class Arithmetic
    attr_reader :pitch, :other

    def initialize(pitch, other)
      @pitch = pitch
      @other = other
    end

    def sum
      return other.above(pitch) if interval?

      pitch_at(pitch.to_i + other.to_i)
    end

    def difference
      return other.below(pitch) if interval?
      return HeadMusic::Rudiment::ChromaticInterval.get(semitones_apart) if pitch?

      pitch_at(semitones_apart)
    end

    private

    def semitones_apart
      pitch.to_i - other.to_i
    end

    def interval?
      other.is_a?(HeadMusic::Analysis::DiatonicInterval)
    end

    def pitch?
      other.is_a?(HeadMusic::Rudiment::Pitch)
    end

    def pitch_at(number)
      HeadMusic::Rudiment::Pitch.get(number)
    end
  end
end
