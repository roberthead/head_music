# frozen_string_literal: true

# A musical instrument.
# An instrument object can be assigned to a staff object.
# Attributes:
#   name_key: the name of the instrument
#   alias_name_keys: an array of alternative names for the instrument
#   orchestra_section_key: the section of the orchestra (e.g. "strings")
#   family_key: the key for the family of the instrument (e.g. "saxophone")
#   classification_keys: an array of classification_keys
#   transposition: the number of semitones between the written and the sounding pitch (optional, default: 0)
#   default_clefs: the default clef or system of clefs for the instrument
#     - [treble] for instruments that use the treble clef
#     - [treble, bass] for instruments that use the grand staff
#   notation:
#     a hash of default and alternative notation systems,
#     each with a staff's key with an array of hashes
#     including clef and transposition (where applicable)
# Associations:
#   family: the family of the instrument (e.g. "saxophone")
#   orchestra_section: the section of the orchestra (e.g. "strings")
class HeadMusic::Instrument
  include HeadMusic::Named

  INSTRUMENTS = YAML.load_file(File.expand_path("data/instruments.yml", __dir__)).freeze

  def self.get(name)
    result = get_by_name(name) || get_by_name(key_for_name(name)) || get_by_alias(name)
    result || new(name)
  end

  def self.all
    HeadMusic::InstrumentFamily.all
    @all ||=
      INSTRUMENTS.map { |key, _data| get(key) }.sort_by(&:name)
  end

  attr_reader(
    :name_key, :alias_name_keys,
    :family_key, :orchestra_section_key,
    :notation, :classification_keys,
    :fundamental_pitch_spelling, :transposition,
    :default_staves, :default_clefs
  )

  def ==(other)
    to_s == other.to_s
  end

  def translation(locale = :en)
    return name unless name_key

    I18n.translate(name_key, scope: %i[head_music instruments], locale: locale, default: name)
  end

  def family
    return unless family_key

    HeadMusic::InstrumentFamily.get(family_key)
  end

  # Returns true if the instrument sounds at a different pitch than written.
  def transposing?
    transposition != 0
  end

  # Returns true if the instrument sounds at a different register than written.
  def transposing_at_the_octave?
    transposing? && transposition % 12 == 0
  end

  def single_staff?
    default_staves.length == 1
  end

  def multiple_staves?
    default_staves.length > 1
  end

  def pitched?
    return false if default_clefs.compact.uniq == ["percussion"]

    default_clefs.any?
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
        translation = I18n.t("head_music.instruments.#{key}", locale: locale)
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
    initialize_family(record)
    inherit_family_attributes(record)
    initialize_names(record)
    initialize_attributes(record)
  end

  def initialize_family(record)
    @family_key = record["family_key"]
    @family = HeadMusic::InstrumentFamily.get(family_key)
  end

  def inherit_family_attributes(record)
    return unless family

    @orchestra_section_key = family.orchestra_section_key
    @classification_keys = family.classification_keys || []
  end

  def initialize_names(record)
    @name_key = record["name_key"].to_sym
    self.name = I18n.translate(name_key, scope: "head_music.instruments", locale: "en", default: inferred_name)
    @alias_name_keys = record["alias_name_keys"] || []
  end

  def initialize_attributes(record)
    @orchestra_section_key ||= record["orchestra_section_key"]
    @classification_keys = [@classification_keys, record["classification_keys"]].flatten.compact.uniq
    @fundamental_pitch_spelling = record["fundamental_pitch_spelling"]
    @default_staves = (record.dig("notation", "default", "staves") || [])
    @default_clefs = @default_staves.map { |staff| staff["clef"] }
    @transposition = @default_staves&.first&.[]("transposition") || 0
  end

  def inferred_name
    name_key.to_s.tr("_", " ")
  end
end
