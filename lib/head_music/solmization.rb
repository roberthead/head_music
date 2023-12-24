# A scale degree is a number indicating the ordinality of the spelling in the key signature.
# TODO: Rewrite to accept a tonal_center and a scale type.
class HeadMusic::Solmization
  include HeadMusic::Named

  DEFAULT_SOLMIZATION = "solfège"

  RECORDS = YAML.load_file(File.expand_path("solmizations.yml", __dir__)).freeze

  attr_reader :syllables

  def self.get(identifier = nil)
    get_by_name(identifier)
  end

  private_class_method :new

  private

  def initialize(name = nil)
    name = nil if name.empty?
    name ||= DEFAULT_SOLMIZATION
    record = record_for_name(name)
    if record
      initialize_data_from_record(record)
    else
      self.name = name
    end
  end

  def record_for_name(name)
    key = HeadMusic::Utilities::HashKey.for(name)
    RECORDS.detect do |record|
      name_strings = record[:localized_names].map { |localized_name| localized_name[:name] }
      name_keys = name_strings.map { |name_string| HeadMusic::Utilities::HashKey.for(name_string) }
      name_keys.include?(key)
    end
  end

  def initialize_data_from_record(record)
    @syllables = record[:syllables]
    initialize_localized_names(record[:localized_names])
  end

  def initialize_localized_names(list)
    @localized_names = (list || []).map do |name_attributes|
      HeadMusic::Named::LocalizedName.new(**name_attributes.slice(:name, :locale_code, :abbreviation))
    end
  end
end
