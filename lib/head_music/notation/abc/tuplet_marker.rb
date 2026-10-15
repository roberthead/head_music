# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # A tuplet marker, "(p:q:r": put p notes into the time of q for the next r
  # notes. An omitted q follows the ABC 2.1 table, in which 5, 7, and 9 depend
  # on whether the meter is compound; an omitted r is p.
  TupletMarker = Data.define(:actual, :normal, :count) do
    def self.default_normal(actual, compound:)
      case actual
      when 2, 4, 8 then 3
      when 3, 6 then 2
      when 5, 7, 9 then compound ? 3 : 2
      end
    end

    def self.for(numbers, compound:, line: nil)
      actual, normal, count = numbers
      normal ||= default_normal(actual, compound: compound)
      lexeme = "(#{numbers.compact.join(":")}"
      raise ParseError.new("A tuplet of #{actual} needs a q, as in (#{actual}:q:r", line_number: line, snippet: lexeme) unless normal
      raise ParseError.new("A tuplet needs positive numbers", line_number: line, snippet: lexeme) unless [actual, normal, count || 1].all?(&:positive?)

      new(actual: actual, normal: normal, count: count || actual)
    end

    # Nil for a marker such as (3:3, which changes no length.
    def ratio
      HeadMusic::Rudiment::TupletRatio.get([actual, normal]) unless actual == normal
    end
  end
end
