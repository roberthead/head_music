# A module for music rudiments
module HeadMusic::Rudiment; end

# A scale degree is a number indicating the ordinality of the spelling in the key signature.
# TODO: Rewrite to accept a tonal_center and a scale type.
class HeadMusic::Rudiment::Solmization
  include HeadMusic::Named

  DEFAULT_SOLMIZATION = "solfège"

  RECORDS = YAML.load_file(File.expand_path("solmizations.yml", __dir__)).freeze

  attr_reader :syllables

  def self.get(identifier = nil)
    get_by_name(identifier)
  end

  private_class_method :new

  private

  def initialize(name = nil)
    name = nil if name.empty?
    name ||= DEFAULT_SOLMIZATION
    record = record_for_name(name)
    if record
      initialize_data_from_record(record)
    else
      self.name = name
    end
  end

  def record_for_name(name)
    key = HeadMusic::Utilities::HashKey.for(name)
    RECORDS.detect do |record|
      name_strings = [record[:name]] + (record[:aliases] || []) + translation_aliases
      name_keys = name_strings.map { |name_string| HeadMusic::Utilities::HashKey.for(name_string) }
      name_keys.include?(key)
    end
  end

  def initialize_data_from_record(record)
    self.name = record[:name]
    @syllables = record[:syllables]
  end

  def translation_aliases
    @translation_aliases ||= load_translation_aliases
  end

  def load_translation_aliases
    aliases = []
    I18n.config.available_locales.each do |locale|
      translation = I18n.translate("head_music.rudiments.solfege", locale: locale, default: nil)
      aliases << translation if translation && translation != 'solfege'
    end
    aliases.compact.uniq
  end
end
