# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Converts one link of a rhythmic value into a LilyPond duration token.
  # Ties between links are the caller's concern (RenderPlan joins links
  # with the tie mark), so this writer ignores tied_value.
  class DurationWriter
    # LilyPond durations are symbolic: a power-of-two number, or a named
    # command for the values longer than a whole note.
    DURATIONS_BY_UNIT_NAME = {
      "maxima" => "\\maxima",
      "longa" => "\\longa",
      "double whole" => "\\breve",
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

    def self.token(rhythmic_value)
      value = HeadMusic::Rudiment::RhythmicValue.get(rhythmic_value)
      base = DURATIONS_BY_UNIT_NAME.fetch(value.unit_name) do
        raise RenderError, "no LilyPond duration is known for a #{value.unit_name} note"
      end
      base + "." * value.dots
    end
  end
end
