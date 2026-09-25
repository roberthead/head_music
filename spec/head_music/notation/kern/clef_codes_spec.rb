require "spec_helper"

describe HeadMusic::Notation::Kern::ClefCodes do
  {
    "*clefG2" => :treble_clef, "*clefF4" => :bass_clef, "*clefGv2" => :vocal_tenor_clef,
    "*clefC1" => :soprano_clef, "*clefC2" => :mezzo_soprano_clef, "*clefC3" => :alto_clef, "*clefC4" => :tenor_clef
  }.each do |field, name_key|
    it "reads #{field} as the #{name_key}" do
      expect(described_class.clef(field).name_key).to eq name_key.to_s
    end

    it "writes the #{name_key} as #{field}" do
      expect(described_class.clef_field(HeadMusic::Rudiment::Clef.get(name_key))).to eq field
    end
  end

  it "drops an unknown clef" do
    expect(described_class.clef("*clefX")).to be_nil
  end

  it "recognizes a clef interpretation" do
    expect(%w[*clefG2 *k[]].map { |field| described_class.clef?(field) }).to eq [true, false]
  end

  it "writes nothing for a clef outside the table" do
    expect(described_class.clef_field(HeadMusic::Rudiment::Clef.get("sub_bass_clef"))).to be_nil
  end
end
