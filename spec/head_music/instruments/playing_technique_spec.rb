require "spec_helper"

describe HeadMusic::Instruments::PlayingTechnique do
  describe ".get" do
    it "returns the identifier if it is already a PlayingTechnique" do
      technique = described_class.get("stick")
      expect(described_class.get(technique)).to be(technique)
    end

    it "creates a PlayingTechnique from a string" do
      technique = described_class.get("stick")
      expect(technique).to be_a(described_class)
      expect(technique.name_key).to eq("stick")
    end

    it "creates a PlayingTechnique from a symbol" do
      technique = described_class.get(:stick)
      expect(technique).to be_a(described_class)
      expect(technique.name_key).to eq("stick")
    end

    it "converts camelCase to snake_case" do
      technique = described_class.get("rimShot")
      expect(technique.name_key).to eq("rim_shot")
    end

    it "converts PascalCase to snake_case" do
      technique = described_class.get("RimShot")
      expect(technique.name_key).to eq("rim_shot")
    end

    it "returns the same instance for the same technique name" do
      technique1 = described_class.get("legato")
      technique2 = described_class.get("legato")
      expect(technique1).to be(technique2)
    end

    it "returns a technique with nil metadata for unknown techniques" do
      technique = described_class.get("unknown_technique")
      expect(technique.name_key).to eq("unknown_technique")
      expect(technique.origin).to be_nil
    end
  end

  describe ".all" do
    it "returns an array of all techniques" do
      techniques = described_class.all
      expect(techniques).to be_an(Array)
      expect(techniques).not_to be_empty
    end

    it "returns PlayingTechnique objects" do
      techniques = described_class.all
      expect(techniques.first).to be_a(described_class)
    end

    it "includes percussion techniques" do
      techniques = described_class.all
      technique_names = techniques.map(&:name_key)
      expect(technique_names).to include("stick", "pedal", "mallet")
    end

    it "includes common techniques" do
      techniques = described_class.all
      technique_names = techniques.map(&:name_key)
      expect(technique_names).to include("legato", "vibrato", "marcato")
    end

    it "includes string techniques" do
      techniques = described_class.all
      technique_names = techniques.map(&:name_key)
      expect(technique_names).to include("harmonic")
    end

    it "includes harp techniques" do
      techniques = described_class.all
      technique_names = techniques.map(&:name_key)
      expect(technique_names).to include("pres_de_la_table")
    end

    it "returns more than the original 14 percussion-only techniques" do
      expect(described_class.all.length).to be > 14
    end
  end

  describe ".for_scope" do
    it "returns techniques for the common scope" do
      techniques = described_class.for_scope(:common)
      expect(techniques).not_to be_empty
      expect(techniques.map(&:name_key)).to include("legato", "vibrato")
    end

    it "returns techniques for the strings scope" do
      techniques = described_class.for_scope(:strings)
      expect(techniques).not_to be_empty
      expect(techniques.map(&:name_key)).to include("harmonic")
    end

    it "returns techniques for the unpitched_percussion scope" do
      techniques = described_class.for_scope(:unpitched_percussion)
      expect(techniques).not_to be_empty
      expect(techniques.map(&:name_key)).to include("stick", "rim_shot")
    end

    it "returns techniques for the harp scope" do
      techniques = described_class.for_scope(:harp)
      expect(techniques).not_to be_empty
      expect(techniques.map(&:name_key)).to include("pres_de_la_table")
    end

    it "returns techniques for the winds scope" do
      techniques = described_class.for_scope(:winds)
      expect(techniques).not_to be_empty
      expect(techniques.map(&:name_key)).to include("flutter_tongue", "key_clicks", "slap_tongue")
    end

    it "returns techniques for the brass scope" do
      techniques = described_class.for_scope(:brass)
      expect(techniques).not_to be_empty
      expect(techniques.map(&:name_key)).to include("harmon_mute", "cup_mute", "stopped", "cuivre")
    end

    it "returns techniques for the keyboard scope" do
      techniques = described_class.for_scope(:keyboard)
      expect(techniques).not_to be_empty
      expect(techniques.map(&:name_key)).to include("una_corda", "sostenuto_pedal", "mano_destra", "sopra")
    end

    it "accepts string scope names" do
      techniques = described_class.for_scope("common")
      expect(techniques).not_to be_empty
    end

    it "returns empty array for unknown scope" do
      techniques = described_class.for_scope(:unknown_scope)
      expect(techniques).to eq([])
    end
  end

  describe "#name" do
    it "returns the name with underscores replaced by spaces" do
      technique = described_class.get("rim_shot")
      expect(technique.name).to eq("rim shot")
    end

    it "returns the name unchanged if no underscores" do
      technique = described_class.get("stick")
      expect(technique.name).to eq("stick")
    end
  end

  describe "#to_s" do
    it "returns the same value as #name" do
      technique = described_class.get("rim_shot")
      expect(technique.to_s).to eq(technique.name)
    end
  end

  describe "#scopes" do
    it "returns the scopes for a technique" do
      technique = described_class.get("legato")
      expect(technique.scopes).to include("common")
    end

    it "returns multiple scopes when applicable" do
      technique = described_class.get("harmonic")
      expect(technique.scopes).to include("strings")
    end

    it "returns nil for unknown techniques" do
      technique = described_class.get("unknown_technique")
      expect(technique.scopes).to be_nil
    end
  end

  describe "#origin" do
    it "returns the origin language for an Italian technique" do
      technique = described_class.get("legato")
      expect(technique.origin).to eq("italian")
    end

    it "returns the origin language for a French technique" do
      technique = described_class.get("laissez_vibrer")
      expect(technique.origin).to eq("french")
    end

    it "returns the origin language for an English technique" do
      technique = described_class.get("stick")
      expect(technique.origin).to eq("english")
    end

    it "returns nil for unknown techniques" do
      technique = described_class.get("unknown_technique")
      expect(technique.origin).to be_nil
    end
  end

  describe "#meaning" do
    it "returns the meaning for a technique" do
      technique = described_class.get("legato")
      expect(technique.meaning).to eq("tied")
    end

    it "returns the meaning for con_sordino" do
      technique = described_class.get("con_sordino")
      expect(technique.meaning).to eq("with mute")
    end

    it "returns nil for unknown techniques" do
      technique = described_class.get("unknown_technique")
      expect(technique.meaning).to be_nil
    end
  end

  describe "#notations" do
    it "returns the notation variants for a technique" do
      technique = described_class.get("legato")
      expect(technique.notations).to include("legato", "leg.")
    end

    it "returns multiple notation variants" do
      technique = described_class.get("con_sordino")
      expect(technique.notations).to include("con sordino", "con sord.", "mute", "muted", "with mute")
    end

    it "returns nil for techniques without notations" do
      technique = described_class.get("stick")
      expect(technique.notations).to be_nil
    end

    it "returns nil for unknown techniques" do
      technique = described_class.get("unknown_technique")
      expect(technique.notations).to be_nil
    end
  end

  describe "#==" do
    let(:stick) { described_class.get("stick") }
    let(:another_stick) { described_class.get("stick") }
    let(:mallet) { described_class.get("mallet") }

    it "returns true for techniques with the same name_key" do
      expect(stick).to eq(another_stick)
    end

    it "returns false for techniques with different name_keys" do
      expect(stick).not_to eq(mallet)
    end

    it "returns false when compared to a non-PlayingTechnique object" do
      expect(stick).not_to eq("stick")
    end

    it "returns false when compared to nil" do
      expect(stick).not_to be_nil
    end
  end

  describe "#eql?" do
    let(:stick) { described_class.get("stick") }
    let(:another_stick) { described_class.get("stick") }

    it "returns the same value as #==" do
      expect(stick.eql?(another_stick)).to eq(stick == another_stick)
    end
  end

  describe "#hash" do
    let(:stick) { described_class.get("stick") }
    let(:another_stick) { described_class.get("stick") }
    let(:mallet) { described_class.get("mallet") }

    it "returns the same hash for techniques with the same name_key" do
      expect(stick.hash).to eq(another_stick.hash)
    end

    it "returns different hashes for techniques with different name_keys" do
      expect(stick.hash).not_to eq(mallet.hash)
    end

    it "allows techniques to be used as hash keys" do
      hash = {stick => "value1"}
      hash[another_stick] = "value2"
      expect(hash.size).to eq(1)
      expect(hash[stick]).to eq("value2")
    end
  end

  describe "named mixin integration" do
    it "includes HeadMusic::Named" do
      expect(described_class.ancestors).to include(HeadMusic::Named)
    end
  end

  describe "YAML data source" do
    it "loads techniques from playing_techniques.yml" do
      expect(described_class::RECORDS).to be_a(Hash)
      expect(described_class::RECORDS).to have_key("playing_techniques")
    end
  end
end
