# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Finds the catalog instrument an instrument or part name names, in the
  # forms other programs write: "C Clarinet" for the catalog's "clarinet in
  # C", "Trumpet in Bb" for "trumpet", and "Violin 1" for "violin".
  module InstrumentNames
    KEY = "[A-G](?:b|#|♭|♯)?"
    PLAYER_NUMBER = /\s+(?:\d+|[IVX]+)\.?\z/
    LEADING_KEY = /\A(#{KEY})\s+(.+)\z/
    IN_KEY = /\A(.+?)\s+in\s+(#{KEY})\z/i
    ACCIDENTALS = {"b" => "♭", "#" => "♯", "♭" => "♭", "♯" => "♯"}.freeze
    PITCH_KEY_SUFFIXES = {"♭" => "_flat", "♯" => "_sharp"}.freeze

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
      key[0].upcase + ACCIDENTALS.fetch(key[1..], "")
    end

    # The catalog names an instrument in its usual key without the key, as
    # "trumpet" for the trumpet in B♭.
    def in_own_key(instrument, key)
      pitch_key = key[0].downcase + PITCH_KEY_SUFFIXES.fetch(key[1..], "")
      instrument if instrument&.pitch_key.to_s == pitch_key
    end

    def get(name)
      HeadMusic::Instruments::Instrument.get(name)
    end
  end
end
