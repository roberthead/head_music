module HeadMusic::Notation::MEI
  # MEI's @dur for a single link of a rhythmic value.
  module Durations
    BY_UNIT_NAME = {
      "maxima" => "maxima",
      "longa" => "long",
      "double whole" => "breve",
      "whole" => "1",
      "half" => "2",
      "quarter" => "4",
      "eighth" => "8",
      "sixteenth" => "16",
      "thirty-second" => "32",
      "sixty-fourth" => "64",
      "hundred twenty-eighth" => "128",
      "two hundred fifty-sixth" => "256"
    }.freeze

    module_function

    def dur(rhythmic_value)
      BY_UNIT_NAME.fetch(rhythmic_value.unit_name) do
        raise RenderError, "MEI has no duration for a #{rhythmic_value.unit_name}"
      end
    end

    def attributes(rhythmic_value)
      {"dur" => dur(rhythmic_value), "dots" => rhythmic_value.dots.positive? ? rhythmic_value.dots : nil}
    end
  end
end
