require "spec_helper"

describe HeadMusic::Notation::MEI::LayerReader do
  describe "Content.sole" do
    let(:content) { described_class::Content }

    it "is the staff every one names" do
      expect(content.sole([2, 2])).to eq 2
    end

    it "is nil where they name different staves, or some name none" do
      expect([content.sole([1, 2]), content.sole([2, nil]), content.sole([])]).to eq [nil, nil, nil]
    end
  end
end
