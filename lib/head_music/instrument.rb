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
    INSTRUMENTS.map { |key, _data| get(key) }.sort_by(&:name)
  end

  attr_reader :name_key, :family, :standard_staves, :classifications

  def ==(other)
    to_s == other.to_s
  end

  def translation(locale = :en)
    return name unless name_key

    I18n.translate(name_key, scope: [:instruments], locale: locale)
  end

  private_class_method :new

  private

  def initialize(name)
    record = record_for_name(name)
    if record
      initialize_data_from_record(record)
    else
      self.name = name.to_s
    end
  end

  def record_for_name(name)
    record_for_key(HeadMusic::Utilities::HashKey.for(name)) ||
      record_for_key(key_for_name(name))
  end

  def key_for_name(name)
    INSTRUMENTS.each do |key, _data|
      I18n.config.available_locales.each do |locale|
        translation = I18n.t("instruments.#{key}", locale: locale)
        return key if translation.downcase == name.downcase
      end
    end
    nil
  end

  def record_for_key(key)
    INSTRUMENTS.each do |name_key, data|
      return data.merge!('name_key' => name_key) if name_key.to_s == key.to_s
    end
    nil
  end

  def initialize_data_from_record(record)
    @name_key = record['name_key'].to_sym
    @family = record['family']
    @standard_staves = record['standard_staves'] || []
    @classifications = record['classifications'] || []
    self.name = I18n.translate(name_key, scope: 'instruments', locale: 'en', default: inferred_name)
  end

  def inferred_name
    name_key.to_s.gsub(/_/, ' ')
  end
end
