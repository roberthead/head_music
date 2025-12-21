module HeadMusic::Instruments; end

# A musical instrument with parent-based inheritance.
#
# Instruments can inherit from parent instruments, allowing for a clean
# hierarchy where child instruments override specific attributes while
# inheriting others from their parents.
#
# Examples:
#   trumpet = HeadMusic::Instruments::Instrument.get("trumpet")
#   clarinet_in_a = HeadMusic::Instruments::Instrument.get("clarinet_in_a")
#   clarinet_in_a.parent  # => clarinet
#   clarinet_in_a.pitch_key  # => "a" (own attribute)
#   clarinet_in_a.family_key  # => "clarinet" (inherited from parent)
#
# Attributes:
#   name_key: the primary identifier for the instrument
#   parent_key: optional key referencing the parent instrument
#   family_key: the instrument family (e.g., "clarinet", "trumpet")
#   pitch_key: the pitch designation (e.g., "b_flat", "a", "c")
#   alias_name_keys: alternative names for the instrument
#   range_categories: size/range classifications
#   staff_schemes: notation schemes (to be moved to NotationStyle later)
class HeadMusic::Instruments::Instrument
  include HeadMusic::Named

  INSTRUMENTS = YAML.load_file(File.expand_path("instruments.yml", __dir__)).freeze

  attr_reader :name_key, :parent_key, :alias_name_keys, :range_categories, :staff_schemes_data

  class << self
    # Factory method to get an Instrument instance
    # @param name [String, Symbol] instrument name (e.g., "clarinet", "clarinet_in_a")
    # @param variant_key [String, Symbol, nil] DEPRECATED: variant key (for backward compatibility)
    # @return [Instrument, nil] instrument instance or nil if not found
    def get(name, variant_key = nil)
      return name if name.is_a?(self)

      # Handle two-argument form for backward compatibility
      if variant_key
        combined_name = "#{name}_#{variant_key}"
        result = find_valid_instrument(combined_name) || find_valid_instrument(name.to_s)
      else
        result = find_valid_instrument(name.to_s) || find_valid_instrument(normalize_variant_name(name))
      end

      result
    end

    def find_valid_instrument(name)
      instrument = get_by_name(name)
      instrument&.name_key ? instrument : nil
    end

    def all
      HeadMusic::Instruments::InstrumentFamily.all # Ensure families are loaded first
      @all ||=
        INSTRUMENTS.map { |key, _data| get(key) }.compact.sort_by { |instrument| instrument.name.downcase }
    end

    private

    # Convert shorthand variant names to full form
    # e.g., "trumpet_in_eb" -> "trumpet_in_e_flat"
    # e.g., "clarinet_in_bb" -> "clarinet_in_b_flat"
    def normalize_variant_name(name)
      name_str = name.to_s

      # Match patterns like "_in_eb" or "_in_bb" at the end (flat)
      flat_pattern = /^(.+)_in_([a-g])b$/i
      sharp_pattern = %r{^(.+)_in_([a-g])\#$}i

      if name_str =~ flat_pattern
        instrument = Regexp.last_match(1)
        note = Regexp.last_match(2).downcase
        "#{instrument}_in_#{note}_flat"
      elsif name_str =~ sharp_pattern
        instrument = Regexp.last_match(1)
        note = Regexp.last_match(2).downcase
        "#{instrument}_in_#{note}_sharp"
      else
        name_str
      end
    end
  end

  # Parent instrument (for inheritance)
  def parent
    return nil unless parent_key

    @parent ||= self.class.get(parent_key)
  end

  # Attributes with parent chain resolution

  def family_key
    @family_key || parent&.family_key
  end

  def pitch_key
    @pitch_key || parent&.pitch_key
  end

  def family
    return unless family_key

    HeadMusic::Instruments::InstrumentFamily.get(family_key)
  end

  def orchestra_section_key
    family&.orchestra_section_key
  end

  def classification_keys
    family&.classification_keys || []
  end

  # Pitch designation as a Spelling object (for backward compatibility)
  def pitch_designation
    return nil unless pitch_key

    @pitch_designation ||= HeadMusic::Rudiment::Spelling.get(pitch_key_to_designation)
  end

  # Staff schemes (notation concern - kept for backward compatibility)
  def staff_schemes
    @staff_schemes ||= build_staff_schemes
  end

  def default_staff_scheme
    @default_staff_scheme ||=
      staff_schemes.find(&:default?) || staff_schemes.first
  end

  def default_staves
    default_staff_scheme&.staves || []
  end

  def default_clefs
    default_staves&.map(&:clef) || []
  end

  def sounding_transposition
    default_staves&.first&.sounding_transposition || 0
  end

  alias_method :default_sounding_transposition, :sounding_transposition

  def transposing?
    sounding_transposition != 0
  end

  def transposing_at_the_octave?
    transposing? && sounding_transposition % 12 == 0
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

  def translation(locale = :en)
    return name unless name_key

    I18n.translate(name_key, scope: %i[head_music instruments], locale: locale, default: name)
  end

  def ==(other)
    return false unless other.is_a?(self.class)

    name_key == other.name_key
  end

  def to_s
    name
  end

  # For backward compatibility with code that expects variants
  def variants
    []
  end

  def default_variant
    nil
  end

  # Collect all instrument_configurations from self and ancestors
  def instrument_configurations
    own_configs = @instrument_configurations || []
    parent_configs = parent&.instrument_configurations || []
    own_configs + parent_configs
  end

  private_class_method :new

  private

  def initialize(name)
    record = record_for_name(name)
    if record
      initialize_data_from_record(record)
    else
      # Mark as invalid - will be filtered out by get_by_name
      @name_key = nil
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
      return data.merge("name_key" => name_key) if name_key.to_s == key.to_s
    end
    nil
  end

  def record_for_alias(name)
    normalized_name = HeadMusic::Utilities::HashKey.for(name).to_s
    INSTRUMENTS.each do |name_key, data|
      data["alias_name_keys"]&.each do |alias_key|
        return data.merge("name_key" => name_key) if HeadMusic::Utilities::HashKey.for(alias_key).to_s == normalized_name
      end
    end
    nil
  end

  def initialize_data_from_record(record)
    @name_key = record["name_key"].to_sym
    @parent_key = record["parent_key"]&.to_sym
    @family_key = record["family_key"]
    @pitch_key = record["pitch_key"]
    @alias_name_keys = record["alias_name_keys"] || []
    @range_categories = record["range_categories"] || []
    @staff_schemes_data = record["staff_schemes"] || {}
    @instrument_configurations = [] # Will be populated when we add configuration support

    initialize_name
  end

  def initialize_name
    # Try to get a translation first
    base_name = I18n.translate(name_key, scope: "head_music.instruments", locale: "en", default: nil)

    if base_name
      # Use the translation as-is
      self.name = base_name
    elsif parent_key && pitch_key
      # Build name from parent + pitch for child instruments
      pitch_name = format_pitch_name(pitch_key_to_designation)
      self.name = "#{parent_translation} in #{pitch_name}"
    else
      # Fall back to inferred name
      self.name = inferred_name
    end
  end

  def parent_translation
    return nil unless parent_key

    I18n.translate(parent_key, scope: "head_music.instruments", locale: "en", default: parent_key.to_s.tr("_", " "))
  end

  def inferred_name
    name_key.to_s.tr("_", " ")
  end

  def format_pitch_name(pitch_designation)
    pitch_designation.to_s.tr("b", "♭").tr("#", "♯")
  end

  # Convert pitch_key (e.g., "b_flat") to designation format (e.g., "Bb")
  def pitch_key_to_designation
    return nil unless pitch_key

    key = pitch_key.to_s
    if key.end_with?("_flat")
      "#{key[0].upcase}b"
    elsif key.end_with?("_sharp")
      "#{key[0].upcase}#"
    else
      key.upcase
    end
  end

  def build_staff_schemes
    return parent&.staff_schemes || [] if staff_schemes_data.empty?

    staff_schemes_data.map do |key, list|
      HeadMusic::Instruments::StaffScheme.new(
        key: key,
        instrument: self,
        list: list
      )
    end
  end
end
