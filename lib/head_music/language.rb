# frozen_string_literal: true

# A language.
class HeadMusic::Language
  include Comparable
  include HeadMusic::NamedRudiment

  LANGUAGES = [
    { name: 'American English', short_name: 'English', abbreviation: 'en-US' },
    { name: 'British English', abbreviation: 'en-GB' },
    { name: 'French', native_name: 'Français', abbreviation: 'fr' },
    { name: 'German', native_name: 'Deutsche', abbreviation: 'de' },
    { name: 'Italian', native_name: 'Italiano', abbreviation: 'it' },
    { name: 'Spanish', native_name: 'Español', abbreviation: 'es' },
    { name: 'Russian', native_name: 'русский', abbreviation: 'ru' },
  ].freeze

  LANGUAGES.
    map { |language| ::HeadMusic::Utilities::HashKey.for(language[:name]) }.
    each { |language_key| define_singleton_method(language_key) { HeadMusic::Language.get(language_key) } }

  LANGUAGES.
    map { |language| ::HeadMusic::Utilities::HashKey.for(language[:native_name]) }.
    reject(&:nil?).
    each { |language_key| define_singleton_method(language_key) { HeadMusic::Language.get(language_key) } }

  LANGUAGES.
    map { |language| ::HeadMusic::Utilities::HashKey.for(language[:short_name]) }.
    reject(&:nil?).
    each { |language_key| define_singleton_method(language_key) { HeadMusic::Language.get(language_key) } }

  def self.default
    english
  end

  def self.get(name)
    get_by_name(name) || default
  end

  attr_accessor :name, :native_name, :short_name

  def initialize(identifier)
    identifier_key = HeadMusic::Utilities::HashKey.for(identifier)
    language_data = LANGUAGES.detect do |data|
      %i[name native_name short_name].
        map { |key| HeadMusic::Utilities::HashKey.for(data[key]) }.
        include?(identifier_key)
    end
    @name = language_data[:name]
    @native_name = language_data[:native_name]
    @short_name = language_data[:short_name]
  end

  def <=>(other)
    name.to_s <=> other.to_s
  end

  def inspect
    [name, native_name, short_name].reject(&:nil?).join(' / ')
  end
end
