require "spec_helper"

describe HeadMusic::Notation::MEI do
  let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nT:Tune\nM:4/4\nL:1/4\nK:C\nCDEF|G4|]\n") }

  describe ".render" do
    it "renders a flow as an MEI document" do
      expect(described_class.render(flow)).to include(%(<mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.1">))
    end

    it "renders what Flow#to_mei renders" do
      expect(flow.to_mei(arranger: "Ann")).to eq described_class.render(flow, arranger: "Ann")
    end

    it "renders the same flow the same way twice" do
      first = described_class.render(flow)
      expect(described_class.render(flow)).to eq first
    end
  end

  describe described_class::RenderError do
    it "is a notation render error" do
      expect(described_class.new("Bad")).to be_a HeadMusic::Notation::RenderError
    end
  end
end
