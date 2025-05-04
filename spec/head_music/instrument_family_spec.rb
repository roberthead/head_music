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

      specify do
        expect(instance.classification_keys).to match_array(
          %w[aerophone reed double_reed wind woodwind]
        )
      end

      specify do
        expect(instance.orchestra_section_key).to eq "woodwind"
      end
    end
  end

  describe ".all" do
    subject { described_class.all }

    its(:length) { is_expected.to be > 1 }

    its(:first) { is_expected.to be_a described_class }
  end
end
