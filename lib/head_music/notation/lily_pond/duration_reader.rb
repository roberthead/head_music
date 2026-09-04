# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Converts a token's duration text into a rhythmic value, carrying the
  # last explicit duration forward for notes that omit theirs. LilyPond's
  # carry-over is global to the input rather than per voice, so one reader
  # serves a whole parse.
  class DurationReader
    DEFAULT_DURATION = "4"
    MAX_DOTS = 3

    # The inverse of the writer's table, built lazily because the reader
    # loads before the writer.
    def self.unit_names_by_duration
      @unit_names_by_duration ||= DurationWriter::DURATIONS_BY_UNIT_NAME.invert.freeze
    end

    def initialize
      @last_duration = DEFAULT_DURATION
    end

    def rhythmic_value(token)
      duration = token.duration
      if duration
        value = build(duration, token)
        @last_duration = duration
        value
      else
        build(@last_duration, token)
      end
    end

    # The fraction of a whole note a whole-bar rest spans: its duration
    # times any multiplier (R1*3/4 spans three quarters).
    def whole_bar_fraction(token)
      fraction = HeadMusic::Notation::DottedDuration.dotted_unit_fraction(rhythmic_value(token))
      fraction *= multiplier(token) if token.multiplier
      raise error("A whole-bar rest must span a positive duration", token) unless fraction.positive?

      fraction
    end

    private

    def build(duration, token)
      base = duration.delete(".")
      dots = duration.count(".")
      unit_name = self.class.unit_names_by_duration.fetch(base) do
        raise error(%(Unrecognized duration "#{base}"), token)
      end
      raise error("Too many dots in #{duration}", token) if dots > MAX_DOTS

      HeadMusic::Rudiment::RhythmicValue.new(unit_name, dots: dots)
    end

    def multiplier(token)
      numerator, denominator = token.multiplier.split("/").map(&:to_i)
      denominator ||= 1
      raise error("Zero denominator in duration multiplier", token) if denominator.zero?

      Rational(numerator, denominator)
    end

    def error(message, token)
      ParseError.new(message, line_number: token.line, column: token.column, snippet: token.lexeme)
    end
  end
end
