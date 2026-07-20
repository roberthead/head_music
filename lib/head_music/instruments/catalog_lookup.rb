module HeadMusic::Instruments; end

# Shared lookup of a catalog entry's key by a localized (translated) name.
# Including classes provide #catalog, a Hash of name_key => record whose keys
# match the I18n keys under "head_music.instruments".
module HeadMusic::Instruments::CatalogLookup
  private

  def key_for_name(name)
    catalog.each do |key, _data|
      I18n.config.available_locales.each do |locale|
        translation = I18n.t("head_music.instruments.#{key}", locale: locale)
        return key if translation.downcase == name.downcase
      end
    end
    nil
  end
end
