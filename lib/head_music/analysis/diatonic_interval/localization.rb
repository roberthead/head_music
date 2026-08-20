class HeadMusic::Analysis::DiatonicInterval
  # An interval names itself from its number and its quality rather than from a
  # fixed vocabulary, so its translation has to be looked up by the name it
  # computed rather than registered against it ahead of time. Anything missing
  # along the way -- no locale asked for, no translations loaded, no entry under
  # either heading -- leaves the computed name standing.
  class Localization
    attr_reader :computed_name, :locale_code

    def initialize(computed_name, locale_code)
      @computed_name = computed_name
      @locale_code = locale_code
    end

    def name
      return computed_name unless locale_code

      translated || computed_name
    end

    private

    def translated
      return unless table

      table.dig(:diatonic_intervals, key) || table.dig(:chromatic_intervals, key)
    end

    def table
      translations = I18n.backend.translations[locale_code]
      translations && translations[:head_music]
    end

    def key
      HeadMusic::Utilities::HashKey.for(computed_name)
    end
  end
end
