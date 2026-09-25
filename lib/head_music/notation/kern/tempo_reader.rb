# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads and writes *MM tempo interpretations, which count quarter notes
  # per minute whatever the meter, and may be fractional.
  module TempoReader
    PATTERN = /\A\*MM(\d+(?:\.\d+)?)\z/
    QUARTER = Rational(1, 4)

    module_function

    # A textual marking such as *MM[Andante] carries no number to read.
    def tempo?(field)
      PATTERN.match?(field)
    end

    def tempo(field)
      number = PATTERN.match(field)[1]
      HeadMusic::Rudiment::Tempo.new("quarter", number.include?(".") ? number.to_f : number.to_i)
    end

    def tempo_field(tempo)
      beat = HeadMusic::Notation::DottedDuration.dotted_unit_fraction(tempo.beat_value)
      quarters = tempo.beats_per_minute * beat / QUARTER
      "*MM#{(quarters == quarters.round) ? quarters.round : quarters.round(3)}"
    end
  end
end
