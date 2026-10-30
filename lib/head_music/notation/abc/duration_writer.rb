# Parses and renders ABC notation as HeadMusic::Content flows
module HeadMusic::Notation::ABC
  # Converts a HeadMusic::Rudiment::RhythmicDuration back into the ABC note-length
  # multiplier string relative to the tune's unit note length — the inverse of
  # DurationResolver.
  class DurationWriter
    attr_reader :unit_note_length

    def initialize(unit_note_length)
      @unit_note_length = Rational(unit_note_length)
    end

    def multiplier_string(rhythmic_duration)
      multiplier_string_for_fraction(total_fraction(rhythmic_duration), rhythmic_duration)
    end

    # For the part of a duration that falls inside one bar; the rhythmic
    # duration is only named in the error.
    def multiplier_string_for_fraction(fraction, rhythmic_duration)
      validate_fraction!(fraction, rhythmic_duration)
      format_multiplier(fraction / unit_note_length)
    end

    private

    # The written length, leaving out any tuplet ratio. A tied chain
    # collapses to one multiplier, round-tripping tokens like "A5".
    def total_fraction(rhythmic_duration)
      values = rhythmic_duration.respond_to?(:values) ? rhythmic_duration.values : [rhythmic_duration]
      values.sum do |value|
        HeadMusic::Notation::DottedDuration.dotted_unit_fraction(value)
      end
    end

    def validate_fraction!(fraction, rhythmic_duration)
      max_fraction = DurationResolver::MAX_FRACTION
      if fraction > max_fraction
        raise_error("note length exceeds #{max_fraction.to_i} whole notes", rhythmic_duration)
      end
      return if HeadMusic::Notation::DottedDuration.power_of_two?(fraction.denominator)

      raise_error("note length #{fraction} is not expressible in binary note values", rhythmic_duration)
    end

    def format_multiplier(multiplier)
      return "" if multiplier == 1
      return multiplier.numerator.to_s if multiplier.denominator == 1

      "#{multiplier.numerator}/#{multiplier.denominator}"
    end

    def raise_error(message, rhythmic_duration)
      raise HeadMusic::Notation::ABC::RenderError, "#{message}: #{rhythmic_duration}"
    end
  end
end
