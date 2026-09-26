require "spec_helper"

describe HeadMusic::Rudiment::KeyedCatalog do
  catalogs = [
    HeadMusic::Rudiment::Articulation,
    HeadMusic::Rudiment::Ornament,
    HeadMusic::Rudiment::Dynamic
  ]
  locale_codes = %w[en de es fr it ru]

  catalogs.each do |catalog|
    describe catalog.name do
      locale_codes.each do |locale_code|
        it "has a translation for every key in #{locale_code}" do
          path = File.expand_path("../../../lib/head_music/locales/#{locale_code}.yml", __dir__)
          scope = catalog.translation_scope.split(".").last
          translations = YAML.load_file(path).dig(locale_code, "head_music", scope) || {}
          expect(catalog.all.map(&:name_key) - translations.keys).to be_empty
        end
      end

      it "falls back to English in en_GB" do
        marking = catalog.all.first
        expect(marking.name(locale_code: :en_GB)).to eq marking.name(locale_code: :en)
      end

      it "answers nil for an unknown key" do
        expect(catalog.get(:bogus)).to be_nil
      end

      it "answers the instance it is given" do
        marking = catalog.all.first
        expect(catalog.get(marking)).to be marking
      end

      it "finds a marking by name as by key" do
        marking = catalog.all.last
        expect(catalog.get_by_name(marking.name_key)).to be marking
      end

      it "freezes its instances" do
        expect(catalog.all).to all(be_frozen)
      end
    end
  end
end
