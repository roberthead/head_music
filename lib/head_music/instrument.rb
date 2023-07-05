# frozen_string_literal: true

# A musical instrument.
# An instrument object can be assigned to a staff object.
# Attributes:
#   name_key: the name of the instrument
#   alias_name_keys: an array of alternative names for the instrument
#   orchestra_section_key: the section of the orchestra (e.g. "strings")
#   instrument_family_key: the key for the family of the instrument (e.g. "saxophone")
#   classification_keys: an array of classification_keys
#   transposition: the number of semitones between the written and the sounding pitch (optional, default: 0)
#   standard_staff_keys: the default clef or system of clefs for the instrument
#     - [treble] for instruments that use the treble clef
#     - [treble, bass] for instruments that use the grand staff
# Associations:
#   instrument_family: the family of the instrument (e.g. "saxophone")
#   orchestra_section: the section of the orchestra (e.g. "strings")
class HeadMusic::Instrument
  include HeadMusic::Named

  INSTRUMENTS = YAML.load_file(File.expand_path("data/instruments.yml", __dir__)).freeze

  def self.get(name)
    result = get_by_name(name) || get_by_name(key_for_name(name))
    result || new(name)
  end

  def self.all
    @all ||=
      INSTRUMENTS.map { |key, _data| get(key) }.sort_by(&:name)
  end

  attr_reader(
    :name_key, :alias_name_keys,
    :instrument_family_key, :orchestra_section_key,
    :standard_staff_keys, :classification_keys
  )

  def ==(other)
    to_s == other.to_s
  end

  def translation(locale = :en)
    return name unless name_key

    I18n.translate(name_key, scope: [:instruments], locale: locale)
  end

  def instrument_family
    return unless instrument_family_key

    HeadMusic::InstrumentFamily.get(instrument_family_key)
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
    INSTRUMENTS.each do |key, _data|
      I18n.config.available_locales.each do |locale|
        translation = I18n.t("instruments.#{key}", locale: locale)
        return key if translation.downcase == name.downcase
      end
    end
    nil
  end

  def record_for_key(key)
    INSTRUMENTS.each do |name_key, data|
      return data.merge!("name_key" => name_key) if name_key.to_s == key.to_s
    end
    nil
  end

  def initialize_data_from_record(record)
    initialize_raw_attributes(record)
    initialize_names(record)
    initialize_associations(record)
    inherit_family_attributes(record)
  end

  def initialize_names(record)
    @name_key = record["name_key"].to_sym
    self.name = I18n.translate(name_key, scope: "instruments", locale: "en", default: inferred_name)
    @alias_name_keys = record["alias_name_keys"] || []
  end

  def initialize_raw_attributes(record)
    @instrument_family_key = record["instrument_family_key"]
    @orchestra_section_key = record["orchestra_section_key"]
    @standard_staff_keys = record["standard_staff_keys"] || []
    @classification_keys = record["classification_keys"] || []
  end

  def initialize_associations(record)
    @instrument_family = HeadMusic::InstrumentFamily.get(instrument_family_key)
  end

  def inherit_family_attributes(record)
    return unless instrument_family

    @orchestra_section_key ||= instrument_family.orchestra_section_key
    @standard_staff_keys = instrument_family.standard_staff_keys if @standard_staff_keys.empty?
    @classification_keys += instrument_family.classification_keys || []
  end

  def inferred_name
    name_key.to_s.tr("_", " ")
  end
end
