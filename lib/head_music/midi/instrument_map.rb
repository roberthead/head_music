module HeadMusic::MIDI
  # The catalog instruments and unpitched sounds that General MIDI programs
  # and percussion keys stand for. A hint is a track or instrument name.
  module InstrumentMap
    module_function

    # +program+ is 1-based. Nil when no catalog instrument has the program.
    def instrument(program, hint: nil)
      nil
    end

    # The generic unpitched sound when no catalog instrument has the key.
    def sound(key, hint: nil)
      HeadMusic::Rudiment::UnpitchedSound.generic
    end
  end
end
