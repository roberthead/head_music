# Parses and renders ABC notation as HeadMusic::Content compositions
module HeadMusic::Notation::ABC
  # Converts a HeadMusic::Rudiment::RhythmicValue back into the ABC note-length
  # multiplier string relative to the tune's unit note length — the inverse of
  # DurationResolver.
  class DurationWriter
    attr_reader :unit_note_length

    def initialize(unit_note_length)
      @unit_note_length = Rational(unit_note_length)
    end

    def multiplier_string(rhythmic_value)
      fraction = total_fraction(rhythmic_value)
      validate_fraction!(fraction, rhythmic_value)
      format_multiplier(fraction / unit_note_length)
    end

    private

    # RhythmicValue's own value methods return Floats; rebuild the fraction
    # from integer parts so the multiplier arithmetic stays exact. A tied
    # chain collapses to one multiplier, round-tripping tokens like "A5".
    def total_fraction(rhythmic_value)
      fraction = single_fraction(rhythmic_value)
      tied_value = rhythmic_value.tied_value
      fraction += total_fraction(tied_value) if tied_value
      fraction
    end

    def single_fraction(rhythmic_value)
      unit = rhythmic_value.unit
      dots = rhythmic_value.dots
      # A value with d dots spans (2^(d+1) - 1) / 2^d of its unit.
      Rational(unit.numerator, unit.denominator) * Rational((2**(dots + 1)) - 1, 2**dots)
    end

    def validate_fraction!(fraction, rhythmic_value)
      max_fraction = DurationResolver::MAX_FRACTION
      if fraction > max_fraction
        raise_error("note length exceeds #{max_fraction.to_i} whole notes", rhythmic_value)
      end
      return if power_of_two?(fraction.denominator)

      raise_error("note length #{fraction} is not expressible in binary note values", rhythmic_value)
    end

    def format_multiplier(multiplier)
      return "" if multiplier == 1
      return multiplier.numerator.to_s if multiplier.denominator == 1

      "#{multiplier.numerator}/#{multiplier.denominator}"
    end

    def power_of_two?(integer)
      (integer & (integer - 1)).zero?
    end

    def raise_error(message, rhythmic_value)
      raise HeadMusic::Notation::ABC::RenderError, "#{message}: #{rhythmic_value}"
    end
  end
end
