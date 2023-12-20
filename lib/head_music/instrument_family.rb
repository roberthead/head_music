# An *InstrumentFamily* is a species of instrument
# that may exist in a variety of keys or other variations.
# For example, _saxophone_ is an instrument family, while
# _alto saxophone_ and _baritone saxophone_ are specific instruments.
class HeadMusic::InstrumentFamily
  include HeadMusic::Named

  INSTRUMENT_FAMILIES =
    YAML.load_file(File.expand_path("data/instrument_families.yml", __dir__)).freeze

  attr_reader :name_key, :classification_keys, :orchestra_section_key
  attr_accessor :name

  def self.get(name)
    result = get_by_name(name) || get_by_name(key_for_name(name))
    result || new(name)
  end

  def self.all
    @all ||=
      INSTRUMENT_FAMILIES.map { |key, _data| get(key) }.sort_by(&:name)
  end

  private_class_method :new

  private

  def initialize(name)
    record = record_for_name(name)
    if record
      initialize_data_from_record(record)
    else
      self.name = name.to_s
    end
  end

  def record_for_name(name)
    record_for_key(HeadMusic::Utilities::HashKey.for(name)) ||
      record_for_key(key_for_name(name))
  end

  def key_for_name(name)
    INSTRUMENT_FAMILIES.each do |key, _data|
      I18n.config.available_locales.each do |locale|
        translation = I18n.t("instruments.#{key}", locale: locale)
        return key if translation.downcase == name.downcase
      end
    end
    nil
  end

  def record_for_key(key)
    INSTRUMENT_FAMILIES.each do |name_key, data|
      return data.merge!("name_key" => name_key) if name_key.to_s == key.to_s
    end
    nil
  end

  def initialize_data_from_record(record)
    @name_key = record["name_key"].to_sym
    @orchestra_section_key = record["orchestra_section_key"]
    @classification_keys = record["classification_keys"] || []
    self.name = I18n.translate(name_key, scope: "instruments", locale: "en", default: inferred_name)
  end

  def inferred_name
    name_key.to_s.tr("_", " ")
  end
end
