# Namespace for instrument definitions, categorization, and configuration
module HeadMusic::Instruments; end

# Represents the mapping of an instrument (and optional playing technique) to a staff position
#
# @example Basic mapping
#   mapping = StaffMapping.new({
#     "staff_position" => 4,
#     "instrument" => "snare_drum"
#   })
#   mapping.instrument.name    #=> "snare drum"
#   mapping.position_index     #=> 4
#
# @example Mapping with playing technique
#   mapping = StaffMapping.new({
#     "staff_position" => -1,
#     "instrument" => "hi_hat",
#     "playing_technique" => "pedal"
#   })
#   mapping.playing_technique.name  #=> "pedal"
class HeadMusic::Instruments::StaffMapping
  attr_reader :staff_position, :instrument_key, :playing_technique_key

  # Initialize a new StaffMapping
  #
  # @param attributes [Hash] the mapping attributes
  # @option attributes [Integer, String] "staff_position" the staff position index
  # @option attributes [String] "instrument" the instrument key
  # @option attributes [String] "playing_technique" optional playing technique key
  def initialize(attributes)
    @staff_position = HeadMusic::Notation::StaffPosition.new(attributes["staff_position"].to_i)
    @instrument_key = attributes["instrument"]
    @playing_technique_key = attributes["playing_technique"]
  end

  # Get the Instrument object
  #
  # @return [Instrument, nil] the instrument or nil if not found
  def instrument
    HeadMusic::Instruments::Instrument.get(instrument_key) if instrument_key
  end

  # Get the PlayingTechnique object
  #
  # @return [PlayingTechnique, nil] the playing technique or nil if not specified
  def playing_technique
    HeadMusic::Instruments::PlayingTechnique.get(playing_technique_key) if playing_technique_key
  end

  # Get the staff position index
  #
  # @return [Integer] the position index
  def position_index
    staff_position.index
  end

  # String representation of this mapping
  #
  # @return [String] human-readable description
  # @example
  #   mapping.to_s  #=> "snare drum at line 3"
  #   mapping.to_s  #=> "hi hat (pedal) at Space 0"
  def to_s
    parts = []
    parts << (instrument&.name || instrument_key) if instrument_key
    parts << "(#{playing_technique})" if playing_technique_key
    parts << "at #{staff_position}"
    parts.compact.join(" ")
  end
end
