# A module for visual music notation
module HeadMusic::Notation
  # Finds the catalog instrument an instrument, part, or staff name names, in
  # the forms other programs write: "C Clarinet" for the catalog's "clarinet
  # in C", "Trumpet in Bb" for "trumpet", and "Violin 1" for "violin".
  module InstrumentNames
    KEY = "[A-G](?:b|#|♭|♯|[- ]?flat|[- ]?sharp)?"
    PLAYER_NUMBER = /\s+(?:\d+|[IVX]+)\.?\z/
    LEADING_KEY = /\A(#{KEY})\s+(.+)\z/
    IN_KEY = /\A(.+?)\s+in\s+(#{KEY})\z/i
    ACCIDENTALS = {"b" => "♭", "#" => "♯", "♭" => "♭", "♯" => "♯", "flat" => "♭", "sharp" => "♯"}.freeze
    SEMITONES = {"C" => 0, "D" => 2, "E" => 4, "F" => 5, "G" => 7, "A" => 9, "B" => 11}.freeze

    module_function

    def instrument(name)
      name = name.to_s.strip
      return if name.empty?

      get(name) || normalized(name.sub(PLAYER_NUMBER, ""))
    end

    def normalized(name)
      base, key = split(name)
      return get(base) unless key

      get("#{base} in #{key}") || in_own_key(get(base), key)
    end

    def split(name)
      in_key = IN_KEY.match(name)
      return [in_key[1], spelled(in_key[2])] if in_key

      leading_key = LEADING_KEY.match(name)
      leading_key ? [leading_key[2], spelled(leading_key[1])] : [name, nil]
    end

    def spelled(key)
      key[0].upcase + ACCIDENTALS.fetch(key[1..].downcase.delete("- "), "")
    end

    # The catalog names an instrument in its usual key without the key, as
    # "trumpet" for the trumpet in B♭. An instrument's key is where its
    # written C sounds.
    def in_own_key(instrument, key)
      sounding = SEMITONES.fetch(key[0]) + {"♭" => -1, "♯" => 1}.fetch(key[1], 0)
      instrument if instrument && (instrument.sounding_transposition - sounding) % 12 == 0
    end

    # "Clarinet" written to sound a minor third low is the clarinet in A.
    def variant(instrument, semitones)
      return instrument if semitones.nil? || instrument.sounding_transposition == semitones

      variants = HeadMusic::Instruments::Instrument.all.select { |variant| variant.parent_key.to_s == instrument.name_key.to_s }
      variants.find { |variant| variant.sounding_transposition == semitones } || instrument
    end

    def get(name)
      HeadMusic::Instruments::Instrument.get(name)
    end
  end
end
