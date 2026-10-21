# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads what follows a \tempo: text, as a string or a markup's words, a
  # metronome mark, or both, as in \tempo "Allegro" 4. = 60. A range, as in
  # 4 = 100-120, reads as its first number.
  class TempoReader
    def initialize(cursor)
      @cursor = cursor
      @duration_reader = DurationReader.new
    end

    # Nil for a \tempo of blank text alone, which says nothing.
    def read(command)
      text = read_text
      metronome = cursor.accept(:metronome)
      raise cursor.error("\\tempo expects text or a metronome mark", cursor.peek || command) unless text || metronome

      text = nil if text&.strip&.empty?
      return HeadMusic::Rudiment::Tempo.for_text(text) if text && !metronome
      return unless metronome

      HeadMusic::Rudiment::Tempo.new(beat_value(metronome), beats_per_minute(metronome), text: text)
    end

    private

    attr_reader :cursor, :duration_reader

    def read_text
      return cursor.markup_text if cursor.markup?

      cursor.accept(:string)&.lexeme
    end

    def beat_value(metronome)
      duration_reader.beat_value(metronome)
    end

    def beats_per_minute(metronome)
      count = metronome.lexeme[Lexer::METRONOME_PATTERN, 2].to_i
      raise cursor.error("A \\tempo must count a positive number of beats per minute", metronome) unless count.positive?

      count
    end
  end
end
