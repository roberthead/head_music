module HeadMusic::Named
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
end
