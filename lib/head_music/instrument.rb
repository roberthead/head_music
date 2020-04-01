# frozen_string_literal: true

# An instrument can be assigned to a staff.
class HeadMusic::Instrument
  include HeadMusic::Named

  INSTRUMENTS = [
    {
      localized_names: [
        { name: 'violin', abbreviation: 'Vn' },
        { name: 'fiddle' },
        { name: 'violín', locale_code: 'es' },
        { name: 'violon', locale_code: 'fr' },
        { name: 'Violine', locale_code: 'de' },
        { name: 'Geige', locale_code: 'de' },
        { name: 'violino', locale_code: 'it' },
      ],
      family: :string,
      default_clef: :treble_clef,
    },
    {
      localized_names: [
        { name: 'viola', abbreviation: 'Vla' },
        { name: 'viola', locale_code: 'es' },
        { name: 'alto', locale_code: 'fr' },
        { name: 'Bratsche', locale_code: 'de', abbreviation: 'Br' },
        { name: 'Viola', locale_code: 'it' },
      ],
      family: :string,
      default_clef: :treble_clef,
    },
    {
      localized_names: [
        { name: 'piano' },
        { name: 'piano', locale_code: 'es' },
        { name: 'piano', locale_code: 'fr' },
        { name: 'piano', locale_code: 'it' },
        { name: 'Piano', locale_code: 'de' },
        { name: 'Klavier', locale_code: 'de' },
      ],
      family: :string,
      default_system: %i[treble_clef bass_clef],
    },
  ].freeze

  def self.get(name)
    get_by_name(name)
  end

  attr_reader :family, :default_clef, :default_system

  def ==(other)
    to_s == other.to_s
  end

  private_class_method :new

  private

  def initialize(name)
    record = record_for_name(name)
    if record
      initialize_data_from_record(record)
    else
      self.name = name
    end
  end

  def record_for_name(name)
    key = HeadMusic::Utilities::HashKey.for(name)
    INSTRUMENTS.detect do |instrument_record|
      name_strings = instrument_record[:localized_names].map { |localized_name| localized_name[:name] }
      name_keys = name_strings.map { |name_string| HeadMusic::Utilities::HashKey.for(name_string) }
      name_keys.include?(key)
    end
  end

  def initialize_data_from_record(record)
    @family = record[:family]
    @default_clef = record[:default_clef]
    @default_system = record[:default_system]
    @localized_names = record[:localized_names].map do |name_attributes|
      HeadMusic::Named::LocalizedName.new(name_attributes.slice(:name, :locale_code, :abbreviation))
    end
  end
end
