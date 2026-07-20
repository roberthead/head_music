module HeadMusic::Instruments; end

class HeadMusic::Instruments::ScoreOrder
  include HeadMusic::Named

  SCORE_ORDERS = YAML.load_file(File.expand_path("score_orders.yml", __dir__)).freeze

  DEFAULT_ENSEMBLE_TYPE_KEY = :orchestral

  attr_reader :ensemble_type_key, :sections

  # Factory method to get a ScoreOrder instance for a specific ensemble type
  def self.get(ensemble_type)
    @instances ||= {}
    key = HeadMusic::Utilities::HashKey.for(ensemble_type)
    return unless SCORE_ORDERS.key?(key.to_s)

    @instances[key] ||= new(key)
  end

  # Convenience method to order instruments in orchestral order
  def self.in_orchestral_order(instruments)
    get(:orchestral).order(instruments)
  end

  # Convenience method to order instruments in concert band order
  def self.in_band_order(instruments)
    get(:band).order(instruments)
  end

  # Accepts a list of instruments and orders them according to this ensemble type's conventions
  def order(instruments)
    ordering_index = build_ordering_index
    known, unknown = partition_by_known_position(normalize_inputs(instruments), ordering_index)
    sort_known(known) + unknown.sort_by(&:to_s)
  end

  private_class_method :new

  private

  def initialize(ensemble_type_key = DEFAULT_ENSEMBLE_TYPE_KEY)
    @ensemble_type_key = ensemble_type_key.to_sym
    data = SCORE_ORDERS[ensemble_type_key.to_s]

    @sections = data["sections"] || []
    self.name = data["name"] || ensemble_type_key.to_s.tr("_", " ").capitalize
  end

  # Discards blank inputs and converts the rest to Instrument objects
  def normalize_inputs(instruments)
    valid_inputs = instruments.compact.reject { |i| i.respond_to?(:empty?) && i.empty? }
    valid_inputs.map { |i| normalize_to_instrument(i) }.compact
  end

  # Splits instruments into those with a known score position and those without
  def partition_by_known_position(instrument_objects, ordering_index)
    known = []
    unknown = []
    instrument_objects.each do |instrument|
      position_info = find_position_with_transposition(instrument, ordering_index)
      if position_info
        known << [instrument, position_info]
      else
        unknown << instrument
      end
    end
    [known, unknown]
  end

  # Sorts known instruments by position (primary) and transposition (secondary)
  def sort_known(known)
    known.sort_by { |_, pos_info| [pos_info[:position], -pos_info[:transposition]] }.map(&:first)
  end

  def normalize_to_instrument(input)
    # Return if already an Instrument instance
    return input if input.is_a?(HeadMusic::Instruments::Instrument)

    # Return other objects that respond to required methods (mock objects, etc.)
    return input if input.respond_to?(:name_key) && input.respond_to?(:family_key)

    # Create an Instrument instance for string inputs
    HeadMusic::Instruments::Instrument.get(input)
  end

  # Builds an index mapping instrument names to their position in the order
  def build_ordering_index
    index = {}
    position = 0

    sections.each do |section|
      instruments = section["instruments"] || []
      instruments.each do |instrument_key|
        # Store position for this instrument key
        index[instrument_key.to_s] = position
        position += 1
      end
    end

    index
  end

  # Finds the position of an instrument in the ordering.
  # Positions are non-negative integers, so a nil lookup safely means "absent".
  def find_position(instrument, ordering_index)
    position_by_name_key(instrument, ordering_index) ||
      position_by_family(instrument, ordering_index) ||
      position_by_normalized_name(instrument, ordering_index)
  end

  # Exact match on the instrument's name_key
  def position_by_name_key(instrument, ordering_index)
    return nil unless instrument.name_key

    ordering_index[instrument.name_key.to_s]
  end

  # Match a family variant (e.g., alto_saxophone -> saxophone family)
  def position_by_family(instrument, ordering_index)
    return nil unless instrument.family_key

    family_base = instrument.family_key.to_s
    instrument_key = instrument.name_key.to_s
    return nil unless instrument_key.include?(family_base)

    # Prefer the specific variant, then fall back to the generic family instrument
    ordering_index[instrument_key] || ordering_index[family_base]
  end

  # Match the normalized (lowercase, underscored) display name
  def position_by_normalized_name(instrument, ordering_index)
    ordering_index[HeadMusic::Utilities::Case.to_snake_case(instrument.name)]
  end

  # Finds the position and transposition information for an instrument
  def find_position_with_transposition(instrument, ordering_index)
    position = find_position(instrument, ordering_index)
    return nil unless position

    # Get the sounding transposition for secondary sorting
    transposition = instrument.default_sounding_transposition || 0

    {position: position, transposition: transposition}
  end
end
