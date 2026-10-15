# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Converts a kern duration (a reciprocal such as "4", "8.", "0", or the
  # rational form "1%3") into a rhythmic value and its exact fraction of
  # a whole note.
  #
  # A reciprocal names the note that many fit in a whole note, so 4 is a
  # quarter; zeros name the long values (0 a breve, 00 a longa). N%M is M/N
  # of a whole note.
  #
  # Kern writes what sounds, not a ratio, so a tuplet's ratio is worked out
  # from the undotted value p/q. When q has an odd factor m, m notes take the
  # time of the largest odd part of p times a power of two below m: 12 is a
  # 3:2 eighth, 20 a 5:4 sixteenth, 10%3 a 5:3 half. Nested tuplets read as
  # their one flattened ratio, and a duplet reads as a dotted value, since
  # that is what it sounds.
  module DurationReader
    MAX_DOTS = 3
    LONG_VALUES = {"0" => 2, "00" => 4, "000" => 8}.freeze
    Duration = Data.define(:rhythmic_value, :fraction)

    module_function

    def duration(recip, dots, line_number: nil, snippet: nil)
      context = {line_number: line_number, snippet: snippet}
      raise ParseError.new("Too many dots in #{recip}#{dots}", **context) if dots.length > MAX_DOTS

      rational = recip.include?("%")
      base = rational ? rational_base(recip, context) : LONG_VALUES.fetch(recip) { Rational(1, positive(recip, context)) }
      fraction = base * dotted_scale(dots.length)
      ratio = HeadMusic::Notation::DottedDuration.tuplet_ratio(base)
      return tuplet(fraction, ratio, context) if ratio

      Duration.new(rational ? rational_value(fraction, recip, context) : reciprocal_value(base, recip, dots.length, context), fraction)
    end

    def tuplet(fraction, ratio, context)
      rhythmic_value = HeadMusic::Notation::DottedDuration.rhythmic_value_for(fraction, tuplet: ratio)
      unless rhythmic_value
        raise UnsupportedFeatureError.new(
          "The #{ratio.to_a.join(":")} tuplet value in #{context[:snippet]} is outside the maxima to 256th", **context
        )
      end

      Duration.new(rhythmic_value, fraction)
    end

    def reciprocal_value(base, recip, dots, context)
      unit = HeadMusic::Notation::DottedDuration.unit_for(base)
      raise ParseError.new(%(Unrecognized duration "#{recip}"), **context) unless unit

      HeadMusic::Rudiment::RhythmicValue.new(unit, dots: dots)
    end

    def rational_base(recip, context)
      denominator, numerator = recip.split("%").map { |number| positive(number, context) }
      Rational(numerator, denominator)
    end

    def rational_value(fraction, recip, context)
      rhythmic_value = HeadMusic::Notation::DottedDuration.rhythmic_value_for(fraction)
      raise ParseError.new(%(Unrecognized duration "#{recip}"), **context) unless rhythmic_value

      rhythmic_value
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
  end
end
