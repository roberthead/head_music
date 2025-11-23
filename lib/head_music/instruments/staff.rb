# Namespace for instrument definitions, categorization, and configuration
module HeadMusic::Instruments; end

class HeadMusic::Instruments::Staff
  DEFAULT_CLEF = "treble_clef"

  attr_reader :staff_scheme, :attributes

  def initialize(staff_scheme, attributes)
    @staff_scheme = staff_scheme
    @attributes = attributes || {}
  end

  def clef
    HeadMusic::Rudiment::Clef.get(smart_clef_key)
  end

  def smart_clef_key
    "#{attributes["clef"]}_clef".gsub(/_clef_clef$/, "_clef")
  end

  def sounding_transposition
    attributes["sounding_transposition"] || 0
  end

  def name_key
    attributes["name_key"] || ""
  end

  def name
    name_key.to_s.tr("_", " ")
  end

  # Get all staff mappings for composite instruments
  #
  # @return [Array<Notation::StaffMapping>] array of staff mappings
  # @example
  #   drum_kit_staff.mappings  #=> [#<Notation::StaffMapping...>, #<Notation::StaffMapping...>]
  def mappings
    @mappings ||= parse_mappings
  end

  # Find the staff mapping at a specific position
  #
  # @param position_index [Integer] the staff position index
  # @return [Notation::StaffMapping, nil] the mapping at that position or nil
  # @example
  #   staff.mapping_for_position(4)  #=> #<Notation::StaffMapping instrument: snare_drum...>
  def mapping_for_position(position_index)
    mappings.find { |mapping| mapping.position_index == position_index }
  end

  # Get the instrument at a specific staff position
  #
  # @param position_index [Integer] the staff position index
  # @return [Instrument, nil] the instrument at that position or nil
  # @example
  #   staff.instrument_for_position(4)  #=> #<Instrument name: "snare drum">
  def instrument_for_position(position_index)
    mapping = mapping_for_position(position_index)
    mapping&.instrument
  end

  # Get all staff positions for a given instrument
  #
  # This is useful for instruments that appear at multiple positions
  # (e.g., hi-hat with stick and pedal techniques)
  #
  # @param instrument_key [String, Symbol] the instrument key
  # @return [Array<Integer>] array of position indices
  # @example
  #   staff.positions_for_instrument("hi_hat")  #=> [-1, 9]
  def positions_for_instrument(instrument_key)
    mappings.select { |mapping| mapping.instrument_key.to_s == instrument_key.to_s }
      .map(&:position_index)
  end

  # Get all unique instruments used in this staff's mappings
  #
  # @return [Array<Instrument>] array of unique instruments
  # @example
  #   drum_kit_staff.components  #=> [#<Instrument: bass_drum>, #<Instrument: snare_drum>, ...]
  def components
    mappings.map(&:instrument).compact.uniq
  end

  private

  def parse_mappings
    mappings_data = attributes["mappings"] || []
    return [] unless mappings_data.is_a?(Array)

    mappings_data.map { |mapping_attrs| HeadMusic::Notation::StaffMapping.new(mapping_attrs) }
  end
end
