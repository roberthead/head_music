require "yaml"

# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Maps the W3C standard sound ids of <instrument-sound> to catalog
  # instruments and back, for the writer and the reader alike. An id outside
  # the table, such as voice.male, names no instrument.
  module InstrumentSounds
    NAME_KEYS_BY_SOUND = YAML.load_file(File.expand_path("instrument_sounds.yml", __dir__)).freeze
    SOUNDS_BY_NAME_KEY = NAME_KEYS_BY_SOUND.each_with_object({}) { |(sound, name_key), sounds| sounds[name_key] ||= sound }.freeze

    module_function

    def instrument(sound)
      name_key = NAME_KEYS_BY_SOUND[sound.to_s.strip]
      name_key && HeadMusic::Instruments::Instrument.get(name_key)
    end

    def sound(instrument)
      SOUNDS_BY_NAME_KEY[instrument&.name_key.to_s]
    end
  end
end
