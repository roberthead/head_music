module HeadMusic::Named
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
end
