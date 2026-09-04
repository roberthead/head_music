# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Converts the argument of a \time command into a meter.
  #
  # The signature is validated textually before Meter.get sees it: the
  # rudiment memoizes whatever it is handed, and a zero numerator makes
  # position arithmetic loop forever.
  class MeterReader
    SIGNATURE_PATTERN = %r{\A(\d+)/(\d+)\z}
    MAX_DENOMINATOR = 256

    def self.meter(token)
      match = token&.type == :number && SIGNATURE_PATTERN.match(token.lexeme)
      top = match && match[1].to_i
      bottom = match && match[2].to_i
      unless match && top.positive? && valid_denominator?(bottom)
        raise ParseError.new(
          %(Invalid \\time signature "#{token&.lexeme}"),
          line_number: token&.line, column: token&.column, snippet: token&.lexeme
        )
      end

      HeadMusic::Rudiment::Meter.get("#{top}/#{bottom}")
    end

    def self.valid_denominator?(bottom)
      bottom.positive? && bottom <= MAX_DENOMINATOR && (bottom & (bottom - 1)).zero?
    end
    private_class_method :valid_denominator?
  end
end
