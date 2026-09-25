# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Converts a kern duration (a reciprocal such as "4", "8.", "0", or the
  # rational form "1%3") into a rhythmic value and its exact fraction of
  # a whole note.
  #
  # A reciprocal names the note that many fit in a whole note, so 4 is a
  # quarter; zeros name the long values (0 a breve, 00 a longa). A
  # reciprocal that is not a power of two is a tuplet, which RhythmicValue
  # cannot yet express.
  module DurationReader
    MAX_DOTS = 3
    LONG_VALUES = {"0" => 2, "00" => 4, "000" => 8}.freeze
    Duration = Data.define(:rhythmic_value, :fraction)

    module_function

    def duration(recip, dots, line_number: nil, snippet: nil)
      context = {line_number: line_number, snippet: snippet}
      raise ParseError.new("Too many dots in #{recip}#{dots}", **context) if dots.length > MAX_DOTS

      recip.include?("%") ? rational(recip, dots.length, context) : reciprocal(recip, dots.length, context)
    end

    def reciprocal(recip, dots, context)
      base = LONG_VALUES.fetch(recip) { Rational(1, positive(recip, context)) }
      unless power_of_two?(base.denominator)
        raise UnsupportedFeatureError.new("Tuplet durations are not supported (#{context[:snippet]})", **context)
      end

      unit = HeadMusic::Notation::DottedDuration.unit_for(base)
      raise ParseError.new(%(Unrecognized duration "#{recip}"), **context) unless unit

      Duration.new(HeadMusic::Rudiment::RhythmicValue.new(unit, dots: dots), base * dotted_scale(dots))
    end

    # N%M is M/N of a whole note: 1%2 is two whole notes.
    def rational(recip, dots, context)
      denominator, numerator = recip.split("%").map { |number| positive(number, context) }
      fraction = Rational(numerator, denominator) * dotted_scale(dots)
      unless power_of_two?(fraction.denominator)
        raise UnsupportedFeatureError.new("Tuplet durations are not supported (#{context[:snippet]})", **context)
      end

      rhythmic_value = HeadMusic::Notation::DottedDuration.rhythmic_value_for(fraction)
      raise ParseError.new(%(Unrecognized duration "#{recip}"), **context) unless rhythmic_value

      Duration.new(rhythmic_value, fraction)
    end

    def positive(number, context)
      value = Integer(number, 10)
      raise ParseError.new(%(Unrecognized duration "#{number}"), **context) unless value.positive?

      value
    end

    # A value with d dots spans (2^(d+1) - 1) / 2^d of its unit.
    def dotted_scale(dots)
      Rational((2**(dots + 1)) - 1, 2**dots)
    end

    def power_of_two?(integer)
      (integer & (integer - 1)).zero?
    end
  end
end
