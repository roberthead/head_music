# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads and writes *M meter interpretations, and the *met(c) and *met(c|)
  # mensuration signs, which draw a 4/4 or 2/2 meter as common or cut time.
  # Other mensuration signs are not read.
  #
  # The signature is validated textually before Meter.get sees it: the
  # rudiment memoizes whatever it is handed, and a zero numerator makes
  # position arithmetic loop forever.
  module MeterReader
    PATTERN = %r{\A\*M(\d+)/(\d+)\z}
    MAX_DENOMINATOR = 256
    SYMBOLS = {"*met(c)" => :common, "*met(c|)" => :cut}.freeze

    module_function

    # *MM is tempo, not meter.
    def meter?(field)
      field.match?(/\A\*M\d/)
    end

    def symbol?(field)
      SYMBOLS.key?(field)
    end

    def symbol(field)
      SYMBOLS.fetch(field)
    end

    def meter(field, line_number: nil)
      match = PATTERN.match(field)
      top = match && match[1].to_i
      bottom = match && match[2].to_i
      unless match && top.positive? && valid_denominator?(bottom)
        raise UnsupportedFeatureError.new(%(Unsupported meter "#{field}"), line_number: line_number, snippet: field)
      end

      HeadMusic::Rudiment::Meter.get("#{top}/#{bottom}")
    end

    # A sign drawing a different meter, such as *met(c) beside *M3/4, is
    # not read.
    def with_symbol(meter, symbol)
      symbolic = HeadMusic::Rudiment::Meter.for_symbol(symbol)
      (symbolic == meter) ? symbolic : meter
    end

    def meter_field(meter)
      "*M#{meter.top_number}/#{meter.bottom_number}"
    end

    def symbol_field(meter)
      SYMBOLS.key(meter.symbol)
    end

    def valid_denominator?(bottom)
      bottom.positive? && bottom <= MAX_DENOMINATOR && (bottom & (bottom - 1)).zero?
    end
  end
end
