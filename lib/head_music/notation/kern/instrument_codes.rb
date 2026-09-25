# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads and writes *I instrument interpretations: a catalog code
  # (*Isoprn), a display name (*I"Soprano), and the class, group, and
  # abbreviation forms (*ICvox, *IGsolo, *I'S.), which are ignored.
  #
  # The codes are the vocal ranges of the Humdrum instrument table and the
  # piano, plus *Ialto, which the Bach chorales use; the first code listed
  # for an instrument is the one written.
  module InstrumentCodes
    INSTRUMENTS_BY_CODE = {
      "soprn" => "soprano_voice",
      "mezzo" => "mezzo_soprano_voice",
      "alto" => "alto_voice",
      "calto" => "alto_voice",
      "tenor" => "tenor_voice",
      "barit" => "baritone_voice",
      "bass" => "bass_voice",
      "piano" => "piano"
    }.freeze
    IGNORED_PREFIXES = %w[*IC *IG *I' *I#].freeze
    CODE = /\A\*I([a-z]\w*)\z/

    module_function

    def transposition?(field)
      field.start_with?("*ITr", "*Tr")
    end

    def name?(field)
      field.start_with?('*I"')
    end

    def name(field)
      field.delete_prefix('*I"')
    end

    def code?(field)
      CODE.match?(field) && IGNORED_PREFIXES.none? { |prefix| field.start_with?(prefix) }
    end

    def code(field)
      CODE.match(field)[1]
    end

    # Nil for a code outside the table, which leaves the part without an
    # instrument rather than guessing one.
    def instrument(code)
      name = INSTRUMENTS_BY_CODE[code]
      name && HeadMusic::Instruments::Instrument.get(name)
    end

    def code_field(instrument)
      code = INSTRUMENTS_BY_CODE.key(instrument&.name_key.to_s)
      "*I#{code}" if code
    end

    def name_field(name)
      %(*I"#{name})
    end
  end
end
