# frozen_string_literal: true

# An instrument can be assigned to a staff.
class HeadMusic::Instrument
  include HeadMusic::Named

  INSTRUMENTS = YAML.load_file(File.expand_path('data/instruments.yml', __dir__)).freeze

  def self.get(name)
    return get_by_name(name) if get_by_name(name)
    return get_by_name(key_for_name(name)) if key_for_name(name)

    new(name)
  end

  def self.all
    INSTRUMENTS.map { |data| get(data['name_key']) }.sort_by(&:name)
  end

  attr_reader :name_key, :family, :default_clefs

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
    record_for_key(key) || record_for_key(key_for_name(name))
  end

  def key_for_name(name)
    INSTRUMENTS.each do |instrument|
      I18n.config.available_locales.each do |locale|
        translation = I18n.t("instruments.#{instrument['name_key']}", locale: locale)
        return instrument['name_key'] if translation.downcase == name.downcase
      end
    end
    nil
  end

  def record_for_key(key)
    INSTRUMENTS.detect { |instrument| instrument['name_key'] == key }
  end

  def initialize_data_from_record(record)
    @family = record['family']
    @default_clefs = record['default_clefs']
    @name_key = record['name_key'].to_sym
    self.name = I18n.translate(name_key, scope: 'instruments', locale: 'en')
  end
end
