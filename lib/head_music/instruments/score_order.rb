module HeadMusic::Instruments; end

class HeadMusic::Instruments::ScoreOrder
  include HeadMusic::Named

  SCORE_ORDERS = YAML.load_file(File.expand_path("score_orders.yml", __dir__)).freeze

  DEFAULT_ENSEMBLE_TYPE_KEY = :orchestral

  attr_reader :ensemble_type_key, :sections

  def self.get(ensemble_type)
    @instances ||= {}
    key = HeadMusic::Utilities::HashKey.for(ensemble_type)
    return unless SCORE_ORDERS.key?(key.to_s)

    @instances[key] ||= new(key)
  end

  def self.in_orchestral_order(instruments)
    get(:orchestral).order(instruments)
  end

  def self.in_band_order(instruments)
    get(:band).order(instruments)
  end

  def order(instruments)
    known, unknown = partition_by_known_position(normalize_inputs(instruments))
    sort_known(known) + unknown.sort_by(&:to_s)
  end

  # Where the instrument sits in the score, counting from the top, or nil where
  # this order does not know it.
  def position_of(instrument)
    entry_for(instrument)&.fetch(:position)
  end

  # Which section the instrument belongs to -- what a score brackets together.
  # Nil where this order does not know the instrument.
  def section_key_of(instrument)
    entry_for(instrument)&.fetch(:section_key)
  end

  # The same instruments as #order, split into their sections. Instruments this
  # order does not know come last, under a nil section key.
  def group(instruments)
    # slice_when rather than chunk, which drops the nil-keyed run that the
    # unknown instruments belong to.
    order(instruments)
      .slice_when { |one, other| section_key_of(one) != section_key_of(other) }
      .map { |members| [section_key_of(members.first), members] }
  end

  private_class_method :new

  private

  def initialize(ensemble_type_key = DEFAULT_ENSEMBLE_TYPE_KEY)
    @ensemble_type_key = ensemble_type_key.to_sym
    data = SCORE_ORDERS[ensemble_type_key.to_s]

    @sections = data["sections"] || []
    self.name = data["name"] || ensemble_type_key.to_s.tr("_", " ").capitalize
  end

  def normalize_inputs(instruments)
    valid_inputs = instruments.compact.reject { |i| i.respond_to?(:empty?) && i.empty? }
    valid_inputs.map { |i| normalize_to_instrument(i) }.compact
  end

  def partition_by_known_position(instrument_objects)
    known = []
    unknown = []
    instrument_objects.each do |instrument|
      position_info = find_position_with_transposition(instrument)
      if position_info
        known << [instrument, position_info]
      else
        unknown << instrument
      end
    end
    [known, unknown]
  end

  def sort_known(known)
    known.sort_by { |_, pos_info| [pos_info[:position], -pos_info[:transposition]] }.map(&:first)
  end

  def entry_for(instrument)
    return nil if instrument.nil?

    normalized = normalize_to_instrument(instrument)
    normalized && find_entry(normalized)
  end

  def normalize_to_instrument(input)
    return input if input.is_a?(HeadMusic::Instruments::Instrument)
    return input if input.respond_to?(:name_key) && input.respond_to?(:family_key)

    HeadMusic::Instruments::Instrument.get(input)
  end

  # One index behind both the ordering and the grouping, so the two cannot
  # disagree about where an instrument belongs.
  def section_index
    @section_index ||= build_section_index
  end

  # A key listed twice -- two trumpets in a quintet -- keeps the last position,
  # which is where the section still ends.
  def build_section_index
    index = {}
    position = 0

    sections.each do |section|
      section_key = section["section_key"]&.to_sym
      instruments = section["instruments"] || []
      instruments.each do |instrument_key|
        index[instrument_key.to_s] = {position: position, section_key: section_key}
        position += 1
      end
    end

    index
  end

  # An entry is a Hash, so a nil lookup safely means "absent".
  def find_entry(instrument)
    entry_by_name_key(instrument) ||
      entry_by_family(instrument) ||
      entry_by_normalized_name(instrument)
  end

  def entry_by_name_key(instrument)
    return nil unless instrument.name_key

    section_index[instrument.name_key.to_s]
  end

  def entry_by_family(instrument)
    return nil unless instrument.family_key

    family_base = instrument.family_key.to_s
    instrument_key = instrument.name_key.to_s
    return nil unless instrument_key.include?(family_base)

    section_index[instrument_key] || section_index[family_base]
  end

  def entry_by_normalized_name(instrument)
    section_index[HeadMusic::Utilities::Case.to_snake_case(instrument.name)]
  end

  def find_position_with_transposition(instrument)
    entry = find_entry(instrument)
    return nil unless entry

    entry.merge(transposition: instrument.default_sounding_transposition || 0)
  end
end
