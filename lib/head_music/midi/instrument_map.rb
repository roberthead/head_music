module HeadMusic::MIDI
  # The catalog instruments and unpitched sounds that General MIDI programs
  # and percussion keys stand for. A hint is a track or instrument name.
  module InstrumentMap
    module_function

    PINNED_PROGRAMS = {
      10 => :glockenspiel,
      16 => :hammered_dulcimer,
      25 => :guitar,
      43 => :cello,
      53 => :soprano_voice,
      57 => :trumpet,
      58 => :trombone,
      59 => :tuba,
      61 => :french_horn,
      65 => :soprano_saxophone,
      68 => :baritone_saxophone,
      69 => :oboe,
      71 => :bassoon,
      72 => :clarinet,
      74 => :flute,
      75 => :recorder
    }.freeze

    PINNED_PERCUSSION_KEYS = {
      36 => :bass_drum,
      40 => :snare_drum,
      44 => :hi_hat,
      46 => :hi_hat,
      49 => :crash_cymbal,
      57 => :crash_cymbal,
      59 => :ride_cymbal,
      76 => :woodblock
    }.freeze

    # +program+ is 1-based. Nil when no catalog instrument has the program.
    def instrument(program, hint: nil)
      hinted = HeadMusic::Instruments::Instrument.get(hint) if hint
      return hinted if hinted && hinted.gm_program == program

      pinned = PINNED_PROGRAMS[program]
      return HeadMusic::Instruments::Instrument.get(pinned) if pinned

      candidates = instruments_by_program.fetch(program, [])
      candidates.first if candidates.one?
    end

    # The generic unpitched sound when no catalog instrument has the key.
    def sound(key, hint: nil)
      hinted = HeadMusic::Instruments::Instrument.get(hint) if hint
      return HeadMusic::Rudiment::UnpitchedSound.new(hinted) if hinted && hinted.gm_percussion_key == key

      pinned = PINNED_PERCUSSION_KEYS[key]
      return HeadMusic::Rudiment::UnpitchedSound.get(pinned) if pinned

      candidates = instruments_by_percussion_key.fetch(key, [])
      return HeadMusic::Rudiment::UnpitchedSound.new(candidates.first) if candidates.one?

      HeadMusic::Rudiment::UnpitchedSound.generic
    end

    def instruments_by_program
      @instruments_by_program ||= catalog.select(&:gm_program).group_by(&:gm_program).freeze
    end

    def instruments_by_percussion_key
      @instruments_by_percussion_key ||= catalog.select(&:gm_percussion_key).group_by(&:gm_percussion_key).freeze
    end

    def catalog
      HeadMusic::Instruments::Instrument::INSTRUMENTS.keys
        .filter_map { |key| HeadMusic::Instruments::Instrument.get(key) }
        .uniq(&:name_key)
    end
  end
end
