# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Reads and writes the value of a Q: field: a beat and its count per minute,
  # quoted tempo text, or both, as in `"Allegro" 1/4=120`. The legacy `Q:120`
  # and `Q:C=120` count unit note lengths. Beats written as several fractions,
  # as in `1/4 3/8=40`, add up, and a beat no single note value spans keeps
  # only the text.
  module TempoField
    TEXT_PATTERN = /"([^"]*)"/
    NUMBER = /(\d+(?:\.\d+)?)/
    BEATS_PATTERN = %r{\A((?:\d+/\d+\s*)+)=\s*#{NUMBER}\z}
    UNIT_PATTERN = /\A(?:C(\d*)\s*=\s*)?#{NUMBER}\z/

    module_function

    # Nil for a field that says nothing the model can hold.
    def read(value, unit_note_length, line_number: nil)
      text = value.scan(TEXT_PATTERN).flatten.map(&:strip).reject(&:empty?).join(" ")
      text = nil if text.empty?
      beat, beats_per_minute = beat_and_count(value.gsub(TEXT_PATTERN, " ").strip, unit_note_length, line_number)
      return HeadMusic::Rudiment::Tempo.new(beat, beats_per_minute, text: text) if beat

      HeadMusic::Rudiment::Tempo.for_text(text) if text
    end

    def write(tempo)
      text = %("#{tempo.text}") if tempo.text
      return text if text && !tempo.metronome_mark?

      [text, "#{fraction(tempo.beat_value.written_fraction)}=#{beats_per_minute(tempo)}"].compact.join(" ")
    end

    # A text the field cannot quote, or a number it cannot write.
    def problem(tempo)
      if tempo.text&.include?('"')
        "the tempo text #{tempo.text.inspect}, which holds a double quote"
      elsif tempo.metronome_mark? && tempo.beats_per_minute != tempo.beats_per_minute.round
        "the fractional tempo of #{tempo.beats_per_minute} beats per minute"
      end
    end

    def beat_and_count(numbers, unit_note_length, line_number)
      return if numbers.empty?

      fraction, count = beat_fraction_and_count(numbers, unit_note_length)
      raise ParseError.new("Invalid tempo #{numbers.inspect}", line_number: line_number, snippet: numbers) unless fraction && count.positive?

      beat = HeadMusic::Notation::DottedDuration.rhythmic_value_for(fraction)
      [beat, count] if beat&.tied_chain&.one?
    end

    def beat_fraction_and_count(numbers, unit_note_length)
      beats = BEATS_PATTERN.match(numbers)
      return [beats[1].split.sum { |beat| Rational(beat) }, number(beats[2])] if beats

      unit = UNIT_PATTERN.match(numbers)
      [unit_note_length * (unit[1].to_s.empty? ? 1 : unit[1].to_i), number(unit[2])] if unit
    end

    def number(digits)
      digits.include?(".") ? digits.to_f : digits.to_i
    end

    def fraction(value)
      "#{value.numerator}/#{value.denominator}"
    end

    def beats_per_minute(tempo)
      tempo.beats_per_minute.round
    end
  end
end
