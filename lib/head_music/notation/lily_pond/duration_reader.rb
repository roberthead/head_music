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
      spanned_fraction(token, "A whole-bar rest")
    end

    # Spacers mark time, as s1*16 marks sixteen bars.
    def spacer_fraction(token)
      spanned_fraction(token, "A spacer")
    end

    # How far into its music an \after places its mark. The duration is
    # \after's own, so it neither uses nor sets the carried one.
    def offset_fraction(token)
      raise error("\\after expects a duration", token) unless token.duration

      own_fraction(token)
    end

    # The sounding time after which a \tuplet or \tupletSpan starts a new
    # bracket, or nil when none is written. Like \after's, it is its own.
    def tuplet_span_fraction(token)
      return unless token.duration

      fraction = own_fraction(token)
      raise error("#{token.lexeme} must span a positive duration", token) unless fraction.positive?

      fraction
    end

    # The beat of a \tempo's metronome mark, which is its own duration.
    def beat_value(token)
      build(token.duration, token)
    end

    private

    def own_fraction(token)
      fraction = HeadMusic::Notation::DottedDuration.dotted_unit_fraction(build(token.duration, token))
      token.multiplier ? fraction * multiplier(token) : fraction
    end

    def spanned_fraction(token, name)
      fraction = HeadMusic::Notation::DottedDuration.dotted_unit_fraction(rhythmic_value(token))
      fraction *= multiplier(token) if token.multiplier
      raise error("#{name} must span a positive duration", token) unless fraction.positive?

      fraction
    end

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
