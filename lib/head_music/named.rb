# NameRudiment is a module to be included in classes whose instances may be identified by name.
module HeadMusic::Named
  delegate :to_s, to: :name

  # Locale encapsulates a language and optional region or country.
  class Locale
    DEFAULT_CODE = :en_US

    attr_reader :language, :region

    def self.default_locale
      get(DEFAULT_CODE)
    end

    def self.get(code)
      @locales ||= {}
      parts = code.to_s.split(/[_-]/)
      language = parts[0].downcase
      region = parts[1]&.upcase
      key = [language, region].compact.join("_").to_sym
      @locales[key] ||= new(language: language, region: region)
    end

    def initialize(language:, region: nil)
      @language = language
      @region = region
    end

    def code
      @code ||= [@language, @region].compact.join("_")
    end

    private_class_method :new
  end

  # A LocalizedName is the name of a rudiment in a locale.
  class LocalizedName
    attr_reader :locale, :name, :abbreviation

    delegate :code, to: :locale, prefix: true
    delegate :language, :region, to: :locale

    def initialize(name:, locale_code: Locale::DEFAULT_CODE, abbreviation: nil)
      @name = name
      @locale = Locale.get(locale_code)
      @abbreviation = abbreviation
    end
  end

  # Adds .get_by_name to the including class.
  module ClassMethods
    def get_by_name(name)
      name = name.to_s
      @instances ||= {}
      key = HeadMusic::Utilities::HashKey.for(name)
      @instances[key] ||= new(name)
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  attr_reader :name_key, :alias_name_keys

  def name=(name)
    ensure_localized_name(name: name)
  end

  def name(locale_code: Locale::DEFAULT_CODE)
    localized_name(locale_code: locale_code)&.name
  end

  def localized_name(locale_code: Locale::DEFAULT_CODE)
    locale = Locale.get(locale_code || Locale::DEFAULT_CODE)
    localized_name_in_matching_locale(locale) ||
      localized_name_in_locale_matching_language(locale) ||
      localized_name_in_default_locale ||
      localized_names.first
  end

  def ensure_localized_name(name:, locale_code: Locale::DEFAULT_CODE, abbreviation: nil)
    @localized_names ||= []
    @localized_names << LocalizedName.new(name: name, locale_code: locale_code, abbreviation: abbreviation)
    @localized_names.uniq!
  end

  # Returns an array of LocalizedName instances that are synonymous with the name.
  def localized_names
    @localized_names ||= []
  end

  private

  def localized_name_in_matching_locale(locale)
    localized_names.detect { |candidate| candidate.locale_code == locale.code }
  end

  def localized_name_in_locale_matching_language(locale)
    localized_names.detect { |candidate| candidate.language == locale.language }
  end

  def localized_name_in_default_locale
    localized_names.detect { |name| name.locale_code == Locale::DEFAULT_CODE }
  end

  def hash_key
    HeadMusic::Utilities::HashKey.for(name)
  end
end
