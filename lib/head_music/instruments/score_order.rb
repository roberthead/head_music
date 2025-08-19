module HeadMusic::Instruments; end

class HeadMusic::Instruments::ScoreOrder
  include HeadMusic::Named

  SCORE_ORDERS = YAML.load_file(File.expand_path("score_orders.yml", __dir__)).freeze

  attr_reader :ensemble_type_key, :sections

  # Factory method to get a ScoreOrder instance for a specific ensemble type
  def self.get(ensemble_type)
    @instances ||= {}
    key = HeadMusic::Utilities::HashKey.for(ensemble_type)
    @instances[key] ||= new(key) if SCORE_ORDERS.key?(key.to_s)
  end

  # Convenience method to order instruments in orchestral order
  def self.in_orchestral_order(instruments)
    get(:orchestral)&.order(instruments) || []
  end

  # Convenience method to order instruments in concert band order
  def self.in_band_order(instruments)
    get(:band)&.order(instruments) || []
  end

  # Orders a list of instruments according to this ensemble type's conventions
  def order(instruments)
    valid_inputs = instruments.compact.reject { |i| i.respond_to?(:empty?) && i.empty? }
    instrument_objects = valid_inputs.map { |i| normalize_to_instrument(i) }.compact

    # Build ordering index
    ordering_index = build_ordering_index

    # Separate known and unknown instruments
    known_instruments = []
    unknown_instruments = []

    instrument_objects.each do |instrument|
      position = find_position(instrument, ordering_index)
      if position
        known_instruments << [instrument, position]
      else
        unknown_instruments << instrument
      end
    end

    # Sort known instruments by position and combine with unknown
    sorted_known = known_instruments.sort_by { |_, position| position }.map(&:first)
    sorted_known + unknown_instruments.sort_by(&:to_s)
  end

  # Returns the list of all instrument keys in order for this ensemble type
  # @return [Array<Symbol>] Ordered list of instrument keys
  def instrument_order
    @instrument_order ||= sections.flat_map { |section| section["instruments"] || [] }.map(&:to_sym)
  end

  private_class_method :new

  private

  def initialize(ensemble_type_key)
    @ensemble_type_key = ensemble_type_key.to_sym
    data = SCORE_ORDERS[ensemble_type_key.to_s]

    if data
      @sections = data["sections"] || []
      self.name = data["name"] || ensemble_type_key.to_s.tr("_", " ").capitalize
    else
      @sections = []
      self.name = ensemble_type_key.to_s.tr("_", " ").capitalize
    end
  end

  def normalize_to_instrument(input)
    return input if input.is_a?(HeadMusic::Instruments::Instrument)

    HeadMusic::Instruments::Instrument.get(input)
  rescue
    nil
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

  # Finds the position of an instrument in the ordering
  def find_position(instrument, ordering_index)
    # Try exact match with name_key
    return ordering_index[instrument.name_key.to_s] if instrument.name_key && ordering_index.key?(instrument.name_key.to_s)

    # Try matching by family + range category (e.g., alto_saxophone -> saxophone family)
    if instrument.family_key
      family_base = instrument.family_key.to_s
      instrument_key = instrument.name_key.to_s

      # Check if this is a variant of a family (e.g., alto_saxophone)
      if instrument_key.include?(family_base)
        # Look for the specific variant first
        return ordering_index[instrument_key] if ordering_index.key?(instrument_key)

        # Fall back to generic family instrument if listed
        return ordering_index[family_base] if ordering_index.key?(family_base)
      end
    end

    # Try normalized name (lowercase, underscored)
    normalized = instrument.name.downcase.tr(" ", "_").tr("-", "_")
    return ordering_index[normalized] if ordering_index.key?(normalized)

    nil
  end
end
