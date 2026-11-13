require "yaml"

# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Maps the W3C standard sound ids of <instrument-sound> to catalog
  # instruments and back, for the writer and the reader alike. An id outside
  # the table, such as voice.male, names no instrument. An instrument with no
  # id of its own writes a shared one, which reads back as its owner, if any.
  module InstrumentSounds
    NAME_KEYS_BY_SOUND = YAML.load_file(File.expand_path("instrument_sounds.yml", __dir__)).freeze
    SOUNDS_BY_NAME_KEY = NAME_KEYS_BY_SOUND.each_with_object({}) { |(sound, name_key), sounds| sounds[name_key] ||= sound }.freeze
    SHARED_SOUNDS_BY_NAME_KEY = YAML.load_file(File.expand_path("shared_instrument_sounds.yml", __dir__)).freeze

    module_function

    def instrument(sound)
      name_key = NAME_KEYS_BY_SOUND[sound.to_s.strip]
      name_key && HeadMusic::Instruments::Instrument.get(name_key)
    end

    # A general sound outside the table, such as wind.reed.saxophone, names
    # the family its more specific sounds share.
    def family_key(sound)
      prefix = "#{sound.to_s.strip}."
      families = NAME_KEYS_BY_SOUND.filter_map do |id, name_key|
        HeadMusic::Instruments::Instrument.get(name_key).family_key if id.start_with?(prefix)
      end
      families.first if families.uniq.one?
    end

    def sound(instrument)
      name_key = instrument&.name_key.to_s
      SOUNDS_BY_NAME_KEY[name_key] || SHARED_SOUNDS_BY_NAME_KEY[name_key]
    end
  end
end
