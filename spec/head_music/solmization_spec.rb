require "spec_helper"

# A Solmization is a system of attributing a distinct syllable to each note in a musical scale.
describe HeadMusic::Solmization do
  describe "construction" do
    context "without an argument" do
      subject(:solmization) { described_class.get }

      it "assumes modern solfège" do
        expect(solmization.name).to eq "solfège"
      end

      its(:syllables) { are_expected.to eq %w[do re mi fa sol la ti] }
    end

    context "when the identifier is 'Solfege' without the diacritical mark" do
      subject(:solmization) { described_class.get("Solfege") }

      its(:syllables) { are_expected.to eq %w[do re mi fa sol la ti] }
    end

    context "when the identifier is not recognized" do
      subject(:solmization) { described_class.get("Guido of Arezzo") }

      its(:syllables) { are_expected.to be_nil }
    end
  end
end
