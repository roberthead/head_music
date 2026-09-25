# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # Converts one link of a rhythmic value into a kern reciprocal: the
  # number of such notes in a whole note, or zeros for the long values,
  # followed by its dots.
  module DurationWriter
    LONG_RECIPROCALS = {1 => "1", 2 => "0", 4 => "00", 8 => "000"}.freeze

    module_function

    def token(link)
      "#{reciprocal(undotted_fraction(link))}#{"." * link.dots}"
    end

    def fraction(link)
      HeadMusic::Notation::DottedDuration.dotted_unit_fraction(link)
    end

    def undotted_fraction(link)
      fraction(link) / DurationReader.dotted_scale(link.dots)
    end

    def reciprocal(base)
      (base >= 1) ? LONG_RECIPROCALS.fetch(base.to_i) : base.denominator.to_s
    end
  end
end
