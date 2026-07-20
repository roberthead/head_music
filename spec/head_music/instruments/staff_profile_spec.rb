require "spec_helper"

describe HeadMusic::Instruments::StaffProfile do
  subject(:profile) { described_class.new(instrument) }

  let(:instrument) { HeadMusic::Instruments::Instrument.get("violin") }

  describe "for a pitched, non-transposing instrument" do
    it "exposes its default clefs" do
      expect(profile.default_clefs).not_to be_empty
    end

    it "is pitched" do
      expect(profile.pitched?).to be true
    end

    it "does not transpose" do
      expect(profile.transposing?).to be false
    end
  end

  describe "when the staff scheme yields nil staves" do
    before do
      scheme = instance_double(HeadMusic::Instruments::StaffScheme, staves: nil)
      allow(HeadMusic::Instruments::StaffScheme).to receive(:new).and_return(scheme)
    end

    it "returns an empty array for default_clefs" do
      expect(profile.default_clefs).to eq([])
    end

    it "returns zero for sounding_transposition" do
      expect(profile.sounding_transposition).to eq(0)
    end
  end

  describe "when there is no default notation" do
    it "resolves to an empty staff-attribute list" do
      empty_style = instance_double(HeadMusic::Notation::NotationStyle, notation_for: nil)
      allow(HeadMusic::Notation::NotationStyle).to receive(:default).and_return(empty_style)
      expect(profile.send(:default_notation_staves_data)).to eq([])
    end
  end
end
