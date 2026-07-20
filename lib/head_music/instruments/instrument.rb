# A module for musical instruments and their properties
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
class HeadMusic::Instruments::Instrument
  include HeadMusic::Named

  INSTRUMENTS = YAML.load_file(File.expand_path("instruments.yml", __dir__)).freeze

  attr_reader :name_key, :parent_key, :alias_name_keys, :range_categories

  class << self
    # Factory method to get an Instrument instance
    # @param name [String, Symbol] instrument name (e.g., "clarinet", "clarinet_in_a")
    # @param variant_key [String, Symbol, nil] DEPRECATED: variant key (for backward compatibility)
    # @return [Instrument, nil] instrument instance or nil if not found
    def get(name, variant_key = nil)
      return name if name.is_a?(self)

      name_str = name.to_s
      if variant_key
        find_valid_instrument("#{name_str}_#{variant_key}") || find_valid_instrument(name_str)
      else
        find_valid_instrument(name_str) || find_valid_instrument(normalize_variant_name(name_str))
      end
    end

    def find_valid_instrument(name)
      instrument = get_by_name(name)
      instrument&.name_key ? instrument : nil
    end

    def all
      HeadMusic::Instruments::InstrumentFamily.all # Ensure families are loaded first
      INSTRUMENTS.map { |key, _data| get(key) }
      @all ||= @instances.values.compact.sort_by { |instrument| instrument.name.downcase }
    end

    private

    # Convert shorthand variant names to full form
    # e.g., "trumpet_in_eb" -> "trumpet_in_e_flat"
    # e.g., "clarinet_in_bb" -> "clarinet_in_b_flat"
    VARIANT_PATTERN = /^(.+)_in_([a-g])([b#])$/i

    def normalize_variant_name(name_str)
      match = VARIANT_PATTERN.match(name_str.to_s)
      return name_str.to_s unless match

      suffix = (match[3] == "b") ? "flat" : "sharp"
      "#{match[1]}_in_#{match[2].downcase}_#{suffix}"
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

  # Notation for this instrument in the given style (defaults to :default).
  def notation(style: :default)
    HeadMusic::Notation::NotationStyle.get(style).notation_for(self)
  end

  # Staff schemes are a notation concern; they now live in NotationStyle.
  # These methods remain for backward compatibility and delegate to the
  # default style. Referenced only inside method bodies, because the Notation
  # module loads after Instruments (see head_music.rb load order).
  def staff_schemes
    [default_staff_scheme]
  end

  def default_staff_scheme
    @default_staff_scheme ||= HeadMusic::Instruments::StaffScheme.new(
      key: "default",
      instrument: self,
      list: default_notation_staves_data
    )
  end

  def default_staves
    default_staff_scheme.staves
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

    HeadMusic::Instruments::InstrumentName.translate(name_key, locale: locale, default: name)
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
    own_configs = HeadMusic::Instruments::InstrumentConfiguration.for_instrument(name_key)
    parent_configs = parent&.instrument_configurations || []
    own_configs + parent_configs
  end

  def stringing
    @stringing ||= HeadMusic::Instruments::Stringing.for_instrument(self) || parent&.stringing
  end

  def alternate_tunings
    own_tunings = HeadMusic::Instruments::AlternateTuning.for_instrument(name_key)
    return own_tunings if own_tunings.any?

    parent&.alternate_tunings || []
  end

  private_class_method :new

  private

  def initialize(name)
    record = HeadMusic::Instruments::InstrumentCatalog.new(INSTRUMENTS).record_for(name)
    if record
      initialize_data_from_record(record)
    else
      # Mark as invalid - will be filtered out by get_by_name
      @name_key = nil
      self.name = name.to_s
    end
  end

  def initialize_data_from_record(record)
    @name_key = record["name_key"].to_sym
    @parent_key = record["parent_key"]&.to_sym
    @family_key = record["family_key"]
    @pitch_key = record["pitch_key"]
    @alias_name_keys = record["alias_name_keys"] || []
    @range_categories = record["range_categories"] || []

    initialize_name
  end

  def initialize_name
    self.name = HeadMusic::Instruments::InstrumentName.new(
      name_key: name_key, parent_key: parent_key, pitch_designation: pitch_key_to_designation
    ).to_s
  end

  # Convert pitch_key (e.g., "b_flat") to designation format (e.g., "Bb")
  def pitch_key_to_designation
    return nil unless pitch_key

    pitch_key_str = pitch_key.to_s
    first_letter = pitch_key_str[0].upcase
    if pitch_key_str.end_with?("_flat")
      "#{first_letter}b"
    elsif pitch_key_str.end_with?("_sharp")
      "#{first_letter}#"
    else
      pitch_key_str.upcase
    end
  end

  # The raw staff-attribute list for this instrument's default notation,
  # resolved from the default NotationStyle.
  def default_notation_staves_data
    notation = HeadMusic::Notation::NotationStyle.default.notation_for(self)
    (notation&.staves || []).map(&:attributes)
  end
end
