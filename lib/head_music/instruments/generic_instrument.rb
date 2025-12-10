# Namespace for instrument definitions, categorization, and configuration
module HeadMusic::Instruments; end

# A generic musical instrument representing a catalog entry.
# A generic instrument defines the base characteristics and available variants (e.g., trumpet, clarinet).
# Attributes:
#   name_key: the name of the instrument
#   alias_name_keys: an array of alternative names for the instrument
#   orchestra_section_key: the section of the orchestra (e.g. "strings")
#   family_key: the key for the family of the instrument (e.g. "saxophone")
#   classification_keys: an array of classification_keys
#   default_clefs: the default clef or system of clefs for the instrument
#     - [treble] for instruments that use the treble clef
#     - [treble, bass] for instruments that use the grand staff
#   variants:
#     a hash of default and alternative pitch designations
# Associations:
#   family: the family of the instrument (e.g. "saxophone")
#   orchestra_section: the section of the orchestra (e.g. "strings")
class HeadMusic::Instruments::GenericInstrument
  include HeadMusic::Named

  INSTRUMENTS = YAML.load_file(File.expand_path("instruments.yml", __dir__)).freeze

  def self.get(name)
    get_by_name(name)
  end

  def self.all
    HeadMusic::Instruments::InstrumentFamily.all # Ensure families are loaded first
    @all ||=
      INSTRUMENTS.map { |key, _data| get(key) }.sort_by { |instrument| instrument.name.downcase }
  end

  attr_reader(
    :name_key, :alias_name_keys,
    :family_key,
    :variants
  )

  delegate :orchestra_section_key, :classification_keys, to: :family, allow_nil: true

  def ==(other)
    to_s == other.to_s
  end

  def translation(locale = :en)
    return name unless name_key

    I18n.translate(name_key, scope: %i[head_music instruments], locale: locale, default: name)
  end

  def family
    return unless family_key

    HeadMusic::Instruments::InstrumentFamily.get(family_key)
  end

  # Returns true if the instrument sounds at a different pitch than written.
  def transposing?
    default_sounding_transposition != 0
  end

  # Returns true if the instrument sounds at a different register than written.
  def transposing_at_the_octave?
    transposing? && default_sounding_transposition % 12 == 0
  end

  def single_staff?
    default_staves.length == 1
  end

  def multiple_staves?
    default_staves.length > 1
  end

  def pitched?
    return false if default_clefs.compact.uniq == [HeadMusic::Rudiment::Clef.get("neutral_clef")]

    default_clefs.any?
  end

  def default_variant
    variants&.find(&:default?) || variants&.first
  end

  def default_instrument
    @default_instrument ||= HeadMusic::Instruments::InstrumentConfiguration.new(self, default_variant)
  end

  def default_staff_scheme
    default_variant&.default_staff_scheme
  end

  def default_staves
    default_staff_scheme&.staves || []
  end

  def default_clefs
    default_staves&.map(&:clef) || []
  end

  def default_sounding_transposition
    default_staves&.first&.sounding_transposition || 0
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
      record_for_key(key_for_name(name)) ||
      record_for_alias(name)
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

  def record_for_alias(name)
    normalized_name = HeadMusic::Utilities::HashKey.for(name).to_s
    INSTRUMENTS.each do |name_key, data|
      data["alias_name_keys"]&.each do |alias_key|
        return data.merge!("name_key" => name_key) if HeadMusic::Utilities::HashKey.for(alias_key).to_s == normalized_name
      end
    end
    nil
  end

  def initialize_data_from_record(record)
    initialize_family(record)
    initialize_names(record)
    initialize_attributes(record)
  end

  def initialize_family(record)
    @family_key = record["family_key"]
    @family = HeadMusic::Instruments::InstrumentFamily.get(family_key)
  end

  def initialize_names(record)
    @name_key = record["name_key"].to_sym
    self.name = I18n.translate(name_key, scope: "head_music.instruments", locale: "en", default: inferred_name)
    @alias_name_keys = record["alias_name_keys"] || []
  end

  def initialize_attributes(record)
    @variants =
      (record["variants"] || {}).map do |key, attributes|
        HeadMusic::Instruments::Variant.new(key, attributes)
      end
  end

  def inferred_name
    name_key.to_s.tr("_", " ")
  end
end
