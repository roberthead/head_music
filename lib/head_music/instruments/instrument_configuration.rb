# Namespace for instrument definitions, categorization, and configuration
module HeadMusic::Instruments; end

# A specific musical instrument configuration with a selected variant.
# Represents an instrument with all configuration choices made (pitch, clef, staff scheme, etc).
#
# Examples:
#   trumpet_in_c = HeadMusic::Instruments::InstrumentConfiguration.get("trumpet_in_c")
#   trumpet_in_c = HeadMusic::Instruments::InstrumentConfiguration.get("trumpet", "in_c")
#   clarinet = HeadMusic::Instruments::InstrumentConfiguration.get("clarinet")  # uses default Bb variant
#
# Attributes accessible via delegation to instrument and variant:
#   name: display name including variant (e.g. "Trumpet in C")
#   transposition: sounding transposition in semitones
#   clefs: array of clefs for this instrument
#   pitch_designation: the pitch designation for transposing instruments
class HeadMusic::Instruments::InstrumentConfiguration
  include HeadMusic::Named

  attr_reader :instrument, :variant

  # Factory method to get an InstrumentConfiguration instance
  # @param instrument_name [String, Symbol] instrument name or full name with variant
  # @param variant_key [String, Symbol, nil] optional variant key if not included in name
  # @return [InstrumentConfiguration] instrument configuration with specified or default variant
  def self.get(instrument_name, variant_key = nil)
    return instrument_name if instrument_name.is_a?(self)

    name, parsed_variant_key = parse_instrument_name(instrument_name)
    variant_key ||= parsed_variant_key

    instrument = HeadMusic::Instruments::Instrument.get(name)
    return nil unless instrument&.name_key

    variant = find_variant(instrument, variant_key)
    new(instrument, variant)
  end

  def initialize(instrument, variant)
    @instrument = instrument
    @variant = variant
    initialize_name
  end

  # Delegations to instrument
  delegate :name_key, :family_key, :family, :orchestra_section_key, :classification_keys,
    :alias_name_keys, :variants, :translation, to: :instrument

  # Delegations to variant
  delegate :pitch_designation, :staff_schemes, :default_staff_scheme, to: :variant

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

  def ==(other)
    return false unless other.is_a?(self.class)

    instrument == other.instrument && variant == other.variant
  end

  def to_s
    name
  end

  private

  def initialize_name
    if variant.default? || !pitch_designation
      self.name = instrument.name
    elsif pitch_designation
      pitch_name = format_pitch_name(pitch_designation)
      self.name = "#{instrument.name} in #{pitch_name}"
    else
      variant_name = variant.key.to_s.tr("_", " ")
      self.name = "#{instrument.name} (#{variant_name})"
    end
  end

  def format_pitch_name(pitch_designation)
    # Format the pitch designation for display
    # e.g. "Bb" -> "B♭", "C" -> "C", "Eb" -> "E♭"
    pitch_designation.to_s.tr("b", "♭").tr("#", "♯")
  end

  def self.parse_instrument_name(name)
    name_str = name.to_s

    # Check for variant patterns like "trumpet_in_e_flat"
    if name_str =~ /(.+)_in_([a-g])_(flat|sharp)$/i
      instrument_name = Regexp.last_match(1)
      note = Regexp.last_match(2).downcase
      accidental = Regexp.last_match(3)
      variant_key = :"in_#{note}_#{accidental}"
      [instrument_name, variant_key]
    # Check for variant patterns like "trumpet_in_c" or "clarinet_in_a" or "trumpet_in_eb"
    elsif name_str =~ /(.+)_in_([a-g][b#]?)$/i
      instrument_name = Regexp.last_match(1)
      variant_note = Regexp.last_match(2).downcase
      # Convert "eb" to "e_flat", "bb" to "b_flat", etc.
      if variant_note.end_with?("b") && variant_note.length == 2
        note_letter = variant_note[0]
        variant_key = :"in_#{note_letter}_flat"
      elsif variant_note.end_with?("#") && variant_note.length == 2
        note_letter = variant_note[0]
        variant_key = :"in_#{note_letter}_sharp"
      else
        variant_key = :"in_#{variant_note}"
      end
      [instrument_name, variant_key]
    else
      [name_str, nil]
    end
  end

  def self.find_variant(instrument, variant_key)
    return instrument.default_variant unless variant_key

    # Convert to symbol for comparison
    variant_sym = variant_key.to_sym

    # Find the variant by key
    variants = instrument.variants || []
    variant = variants.find { |v| v.key == variant_sym }
    variant || instrument.default_variant
  end

  private_class_method :parse_instrument_name, :find_variant
end
