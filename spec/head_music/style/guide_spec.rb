require "spec_helper"

describe HeadMusic::Style::Guide do
  guides = HeadMusic::Style::Guides

  describe ".get" do
    it "resolves a guide class by string key" do
      expect(described_class.get("first_species_harmony")).to eq guides::FirstSpeciesHarmony
    end

    it "resolves a guide class by symbol key" do
      expect(described_class.get(:first_species_harmony)).to eq guides::FirstSpeciesHarmony
    end

    it "resolves a guide that knows its own category" do
      expect(described_class.get("first_species_harmony").category).to eq :harmony
    end

    it "returns nil for an unknown key" do
      expect(described_class.get("does_not_exist")).to be_nil
    end

    it "does not raise for an unknown key" do
      expect { described_class.get("does_not_exist") }.not_to raise_error
    end

    it "treats nil as a miss" do
      expect(described_class.get(nil)).to be_nil
    end

    it "treats an empty string as a miss" do
      expect(described_class.get("")).to be_nil
    end

    # A contour is a configuration value, not a guide key: a consumer storing
    # "arch" must migrate to "arch_contour_melody".
    it "treats a bare contour name as a miss" do
      expect(described_class.get("ascending")).to be_nil
    end

    it "passes a guide class through unchanged" do
      expect(described_class.get(guides::FuxCantusFirmus)).to be guides::FuxCantusFirmus
    end

    it "passes a configured guide through unchanged" do
      configured_guide = guides::ContourMelody.with(contour: :wave, minimum_melodic_intervals: 3)
      expect(described_class.get(configured_guide)).to be configured_guide
    end
  end

  describe ".get!" do
    it "returns the guide for a known key" do
      expect(described_class.get!("fux_cantus_firmus")).to eq guides::FuxCantusFirmus
    end

    it "raises a KeyError naming the unknown key" do
      expect { described_class.get!("does_not_exist") }.to raise_error(KeyError, /does_not_exist/)
    end
  end

  describe ".known?" do
    it "is true for a registered key" do
      expect(described_class).to be_known("wave_contour_melody")
    end

    it "is false for an unregistered key" do
      expect(described_class).not_to be_known("does_not_exist")
    end

    it "is true for a registered guide object, matching key_for" do
      entry = described_class.get("wave_contour_melody")

      expect(described_class).to be_known(entry)
      expect(described_class.key_for(entry)).to eq "wave_contour_melody"
    end

    # known? must not simply ask whether the argument answers analyze, or it
    # would disagree with key_for about the very same object.
    it "is false for an ad-hoc configuration the registry does not hold" do
      ad_hoc = HeadMusic::Style::Guides::ContourMelody.with(contour: :wave, minimum_melodic_intervals: 3)

      expect(described_class).not_to be_known(ad_hoc)
      expect(described_class.key_for(ad_hoc)).to be_nil
    end

    it "is false for the unconfigured contour guide class" do
      expect(described_class).not_to be_known(HeadMusic::Style::Guides::ContourMelody)
    end
  end

  describe ".all" do
    it "enumerates every registered guide" do
      expect(described_class.all.length).to eq 23
    end

    it "registers each guide once" do
      expect(described_class.all.uniq.length).to eq described_class.all.length
    end

    it "categorizes every guide as melody or harmony" do
      expect(described_class.all.map(&:category).uniq).to match_array %i[melody harmony]
    end

    it "gives every guide something to analyze with" do
      expect(described_class.all).to all(respond_to(:analyze))
    end
  end

  describe ".keys" do
    it "returns twenty-three unique keys" do
      expect(described_class.keys.uniq.length).to eq 23
    end

    it "returns strings, since keys cross the storage boundary" do
      expect(described_class.keys).to all(be_a(String))
    end

    it "resolves every key it reports" do
      expect(described_class.keys.map { |key| described_class.get(key) }).to eq described_class.all
    end
  end

  describe ".key_for" do
    it "returns the registered key of a guide class" do
      expect(described_class.key_for(guides::FuxCantusFirmus)).to eq "fux_cantus_firmus"
    end

    it "returns the registered key of a configured guide" do
      expect(described_class.key_for(described_class.get("wave_contour_melody"))).to eq "wave_contour_melody"
    end

    it "returns nil for a configuration that is not in the registry" do
      ad_hoc = guides::ContourMelody.with(contour: :wave, minimum_melodic_intervals: 3)
      expect(described_class.key_for(ad_hoc)).to be_nil
    end
  end

  describe ".display_name_for" do
    it "derives a title from the key" do
      expect(described_class.display_name_for("first_species_harmony")).to eq "First Species Harmony"
    end

    it "prefers a locale entry where the derived title would be wrong" do
      expect(described_class.display_name_for("salzer_schachter_cantus_firmus"))
        .not_to eq "Salzer Schachter Cantus Firmus"
    end

    it "still names the guide when overriding the derived title" do
      expect(described_class.display_name_for("salzer_schachter_cantus_firmus"))
        .to match(/Salzer.Schachter Cantus Firmus/)
    end
  end

  describe "contour guide keys" do
    {
      "arch_contour_melody" => {contour: :arch, minimum_melodic_intervals: 2},
      "ascending_contour_melody" => {contour: :ascending, minimum_melodic_intervals: 1},
      "descending_contour_melody" => {contour: :descending, minimum_melodic_intervals: 1},
      "static_contour_melody" => {contour: :static, minimum_melodic_intervals: nil},
      "valley_contour_melody" => {contour: :valley, minimum_melodic_intervals: 2},
      "wave_contour_melody" => {contour: :wave, minimum_melodic_intervals: 2}
    }.each do |key, options|
      it "resolves #{key} to a configured contour melody guide" do
        expect(described_class.get(key)).to configured_guide(guides::ContourMelody, **options)
      end

      it "keeps #{key} a melodic guide" do
        expect(described_class.get(key).category).to eq :melody
      end

      it "displays #{key} distinctly from its siblings" do
        expect(described_class.get(key).display_name).to eq(
          key.tr("_", " ").split.map(&:capitalize).join(" ")
        )
      end
    end
  end
end
