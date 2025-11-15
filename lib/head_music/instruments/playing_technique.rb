# Namespace for instrument definitions, categorization, and configuration
module HeadMusic::Instruments; end

# A PlayingTechnique represents a specific method of producing sound on an instrument
#
# @example Retrieving a playing technique
#   stick = HeadMusic::Instruments::PlayingTechnique.get(:stick)
#   pedal = HeadMusic::Instruments::PlayingTechnique.get("pedal")
#
# @example Accessing technique properties
#   stick.name          #=> "stick"
#   stick.to_s          #=> "stick"
class HeadMusic::Instruments::PlayingTechnique
  include HeadMusic::Named

  attr_reader :name_key

  # Common playing techniques for various instruments
  TECHNIQUES = %w[
    stick
    pedal
    mallet
    hand
    brush
    rim_shot
    cross_stick
    open
    closed
    damped
    let_ring
    choked
    bow
    bell
  ].freeze

  # Get a PlayingTechnique by name
  #
  # @param identifier [String, Symbol, PlayingTechnique] the technique identifier
  # @return [PlayingTechnique] the playing technique object
  def self.get(identifier)
    return identifier if identifier.is_a?(self)

    name = identifier.to_s.downcase.tr(" ", "_").tr("-", "_")
    new(name)
  end

  # List all known playing techniques
  #
  # @return [Array<PlayingTechnique>] array of all techniques
  def self.all
    TECHNIQUES.map { |technique| new(technique) }
  end

  def initialize(name_key)
    @name_key = name_key.to_s
  end

  def name
    name_key.tr("_", " ")
  end

  def to_s
    name
  end

  def ==(other)
    return false unless other.is_a?(self.class)

    name_key == other.name_key
  end

  def hash
    name_key.hash
  end

  alias_method :eql?, :==
end
