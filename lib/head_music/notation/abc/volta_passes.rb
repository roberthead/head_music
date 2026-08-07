# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Interprets the digits of a volta bracket — "1", "1,3", "2-4" — as the pass
  # numbers on which the bracketed bars play.
  class VoltaPasses
    def self.parse(digits, line_number)
      passes = digits.split(",").flat_map { |part| expand_range(part) }.select(&:positive?)
      ensure_unique(passes, digits, line_number)
      passes
    end

    def self.expand_range(part)
      first, last = part.split("-", 2)
      last ? (first.to_i..last.to_i).to_a : [first.to_i]
    end
    private_class_method :expand_range

    def self.ensure_unique(passes, digits, line_number)
      return if passes.uniq.length == passes.length

      raise ParseError.new(
        "Volta passes must be unique",
        line_number: line_number, snippet: digits
      )
    end
    private_class_method :ensure_unique
  end
end
