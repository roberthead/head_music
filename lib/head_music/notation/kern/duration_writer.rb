# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # Converts one link of a rhythmic value into a kern reciprocal: the
  # number of such notes in a whole note, or zeros for the long values,
  # followed by its dots.
  #
  # Kern writes what sounds, so a tuplet value is written by its length
  # under its ratio: a triplet eighth as 12, its dotted form as 12., and a
  # 5:3 half as 10%3. A value that sounds as a plain or dotted note is
  # written as that note, as Humdrum writes a duplet eighth as 8.
  module DurationWriter
    LONG_RECIPROCALS = {1 => "1", 2 => "0", 4 => "00", 8 => "000"}.freeze

    module_function

    def token(link)
      sounding = fraction(link)
      undotted = sounding / DurationReader.dotted_scale(link.dots)
      dots = "." * link.dots
      return "#{LONG_RECIPROCALS.fetch(undotted.to_i)}#{dots}" if long?(undotted)
      return "#{undotted.denominator}#{dots}" if undotted.numerator == 1

      plain = HeadMusic::Notation::DottedDuration.rhythmic_value_for(sounding)
      return token(plain) if plain

      "#{undotted.denominator}%#{undotted.numerator}#{dots}"
    end

    # The link's sounding length, under its ratio.
    def fraction(link)
      HeadMusic::Notation::DottedDuration.sounding_fraction(link)
    end

    def long?(undotted)
      undotted.denominator == 1 && LONG_RECIPROCALS.key?(undotted.numerator)
    end
  end
end
