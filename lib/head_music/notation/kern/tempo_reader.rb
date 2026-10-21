# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads and writes *MM tempo interpretations, which count quarter notes
  # per minute whatever the meter, and may be fractional, or give the tempo
  # in words, as *MM[Andante].
  #
  # Kern has no ramps, so words that would start one, or "a tempo", are not
  # read as tempo text.
  module TempoReader
    PATTERN = /\A\*MM(\d+(?:\.\d+)?)\z/
    TEXT_PATTERN = /\A\*MM\[([^\]]*)\]\z/
    QUARTER = Rational(1, 4)

    module_function

    def tempo?(field)
      PATTERN.match?(field) || !text(field).nil?
    end

    def tempo(field)
      words = text(field)
      return HeadMusic::Rudiment::Tempo.for_text(words) if words

      number = PATTERN.match(field)[1]
      HeadMusic::Rudiment::Tempo.new("quarter", number.include?(".") ? number.to_f : number.to_i)
    end

    def text(field)
      words = TEXT_PATTERN.match(field)&.[](1)&.strip
      words unless words.nil? || words.empty? || HeadMusic::Notation::TempoMarkReading.word(words)
    end

    # A tempo with words writes them before its number, which is left out
    # when it was not written. Whitespace would split the row, and a bracket
    # end the words.
    def tempo_fields(tempo)
      [
        tempo.text && "*MM[#{tempo.text.gsub(/\s+/, " ").tr("[]", "()")}]",
        (tempo_field(tempo) if tempo.metronome_mark? || tempo.text.nil?)
      ].compact
    end

    def tempo_field(tempo)
      beat = HeadMusic::Notation::DottedDuration.dotted_unit_fraction(tempo.beat_value)
      quarters = tempo.beats_per_minute * beat / QUARTER
      "*MM#{(quarters == quarters.round) ? quarters.round : quarters.round(3)}"
    end
  end
end
