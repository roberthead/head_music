require "spec_helper"

describe HeadMusic::Instruments::InstrumentFamily do
  describe ".get" do
    context "when given an instance" do
      let(:instance) { described_class.get("oboe") }

      it "returns that instance" do
        expect(described_class.get(instance)).to be instance
      end
    end

    context "when given a name" do
      let(:instance) { described_class.get("oboe") }

      it "returns an instance" do
        expect(instance).to be_a described_class
      end

      it "returns an instance with the given name" do
        expect(instance.name).to eq "oboe"
      end

      it "sets the name_key" do
        expect(instance.name_key).to eq :oboe
      end

      specify do
        expect(instance.classification_keys).to match_array(
          %w[aerophone reed double_reed wind woodwind]
        )
      end

      specify do
        expect(instance.orchestra_section_key).to eq "woodwind"
      end
    end

    context "when given a symbol" do
      let(:instance) { described_class.get(:saxophone) }

      it "returns an instance" do
        expect(instance).to be_a described_class
      end

      it "returns an instance with the correct name" do
        expect(instance.name).to eq "saxophone"
      end

      it "sets the name_key" do
        expect(instance.name_key).to eq :saxophone
      end
    end

    context "when given a non-existent family name" do
      let(:instance) { described_class.get("imaginary_instrument") }

      it "returns an instance" do
        expect(instance).to be_a described_class
      end

      it "uses the provided name" do
        expect(instance.name).to eq "imaginary_instrument"
      end

      it "has no name_key" do
        expect(instance.name_key).to be_nil
      end

      it "has no orchestra_section_key" do
        expect(instance.orchestra_section_key).to be_nil
      end

      it "has empty classification_keys" do
        expect(instance.classification_keys).to be_nil
      end
    end

    context "with string instruments" do
      let(:violin_family) { described_class.get("violin") }

      it "has string section" do
        expect(violin_family.orchestra_section_key).to eq "string"
      end

      it "includes bowed and string classifications" do
        expect(violin_family.classification_keys).to include("bowed", "string")
      end
    end

    context "with brass instruments" do
      let(:trumpet_family) { described_class.get("trumpet") }

      it "has brass section" do
        expect(trumpet_family.orchestra_section_key).to eq "brass"
      end

      it "includes brass classification" do
        expect(trumpet_family.classification_keys).to include("brass")
      end
    end

    context "with percussion instruments" do
      let(:snare_drum_family) { described_class.get("snare_drum") }

      it "has percussion section" do
        expect(snare_drum_family.orchestra_section_key).to eq "percussion"
      end

      it "includes percussion classification" do
        expect(snare_drum_family.classification_keys).to include("percussion")
      end
    end

    context "with keyboard instruments" do
      let(:piano_family) { described_class.get("piano") }

      it "has keyboard section" do
        expect(piano_family.orchestra_section_key).to eq "keyboard"
      end

      it "includes keyboard classification" do
        expect(piano_family.classification_keys).to include("keyboard")
      end
    end
  end

  describe ".all" do
    subject(:all_families) { described_class.all }

    it "returns an array" do
      expect(all_families).to be_an Array
    end

    it "returns multiple families" do
      expect(all_families.length).to be > 1
    end

    it "returns InstrumentFamily instances" do
      expect(all_families.first).to be_a described_class
    end

    it "sorts families by name" do
      names = all_families.map(&:name)
      expect(names).to eq names.sort
    end

    it "includes common families" do
      family_names = all_families.map(&:name)
      expect(family_names).to include("violin", "trumpet", "piano", "saxophone")
    end

    it "caches the result" do
      first_call = described_class.all
      second_call = described_class.all
      expect(first_call).to be second_call
    end
  end

  describe "#to_s" do
    it "returns the name" do
      family = described_class.get("oboe")
      expect(family.to_s).to eq "oboe"
    end
  end

  describe "#name_key" do
    it "returns the key as a symbol" do
      family = described_class.get("oboe")
      expect(family.name_key).to eq :oboe
    end

    it "returns nil for non-existent families" do
      family = described_class.get("fake_instrument")
      expect(family.name_key).to be_nil
    end
  end

  describe "#classification_keys" do
    it "returns an array for existing families" do
      family = described_class.get("oboe")
      expect(family.classification_keys).to be_an Array
    end

    it "includes relevant classifications" do
      family = described_class.get("oboe")
      expect(family.classification_keys).to include("woodwind")
    end
  end

  describe "#orchestra_section_key" do
    it "returns the section key for existing families" do
      family = described_class.get("oboe")
      expect(family.orchestra_section_key).to eq "woodwind"
    end

    it "returns nil for non-existent families" do
      family = described_class.get("fake_instrument")
      expect(family.orchestra_section_key).to be_nil
    end
  end
end
