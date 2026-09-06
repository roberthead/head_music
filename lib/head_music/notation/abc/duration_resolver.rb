# Parses ABC notation into HeadMusic::Content flows
module HeadMusic::Notation::ABC
  # Converts the tune's unit note length and a per-note multiplier string
  # (e.g. "2", "3/2", "/", "//") into a HeadMusic::Rudiment::RhythmicValue.
  class DurationResolver
    MAX_FRACTION = HeadMusic::Notation::DottedDuration::MAX_FRACTION

    MULTIPLIER_PATTERN = %r{\A(\d+)?(?:(/+)(\d+)?)?\z}

    attr_reader :unit_note_length

    def initialize(unit_note_length)
      @unit_note_length = Rational(unit_note_length)
    end

    # scale: an extra multiplier applied outside the note's own length
    # string, used for broken-rhythm pairs (3/2 and 1/2).
    def rhythmic_value(multiplier_string, scale: Rational(1))
      fraction = unit_note_length * multiplier(multiplier_string) * scale
      validate_fraction!(fraction, multiplier_string)
      HeadMusic::Notation::DottedDuration.rhythmic_value_for(fraction) ||
        raise_error("no rhythmic unit for a note length of #{fraction}", multiplier_string)
    end

    # The bare fraction a length string denotes (e.g. "2" -> 2, "/2" -> 1/2,
    # "" -> 1), without the unit note length applied. Used to compare a
    # chord's per-note lengths for uniformity.
    def length_fraction(multiplier_string)
      multiplier(multiplier_string)
    end

    private

    def multiplier(multiplier_string)
      source = multiplier_string.to_s
      match = MULTIPLIER_PATTERN.match(source)
      raise_error("malformed note length multiplier", source) unless match

      numerator = (match[1] || 1).to_i
      slashes = match[2]
      denominator = match[3]
      return Rational(numerator) unless slashes
      return Rational(numerator, 2**slashes.length) unless denominator

      explicit_ratio(numerator, slashes, denominator, source)
    end

    def explicit_ratio(numerator, slashes, denominator, source)
      # An explicit denominator pairs with exactly one slash ("3/2", not "3//2").
      raise_error("malformed note length multiplier", source) if slashes.length > 1
      raise_error("note length denominator cannot be zero", source) if denominator.to_i.zero?
      Rational(numerator, denominator.to_i)
    end

    def validate_fraction!(fraction, source)
      raise_error("note length must be positive", source) if fraction <= 0
      raise_error("note length exceeds #{MAX_FRACTION.to_i} whole notes", source) if fraction > MAX_FRACTION
      return if HeadMusic::Notation::DottedDuration.power_of_two?(fraction.denominator)

      raise_error("note length #{fraction} is not expressible in binary note values", source)
    end

    def raise_error(message, source)
      raise HeadMusic::Notation::ABC::ParseError.new(message, snippet: source)
    end
  end
end
