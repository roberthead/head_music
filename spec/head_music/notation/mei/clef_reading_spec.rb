require "spec_helper"

describe HeadMusic::Notation::MEI::ClefReading do
  def clef(attributes)
    element = REXML::Document.new("<clef #{attributes}/>").root
    described_class.clef(element)&.name_key
  end

  def staff_def_clef(xml)
    element = REXML::Document.new(xml).root
    described_class.staff_def_clef(element, HeadMusic::Notation::MEI::Editorial.new(HeadMusic::Notation::MEI::IdIndex.new, budget: 10))&.name_key&.to_sym
  end

  {
    %(shape="G" line="2") => :treble_clef,
    %(shape="F" line="4") => :bass_clef,
    %(shape="C" line="3") => :alto_clef,
    %(shape="C" line="4") => :tenor_clef,
    %(shape="G" line="2" dis="8" dis.place="below") => :vocal_tenor_clef,
    %(shape="perc") => :neutral_clef,
    %(shape="G" line="2" dis="15" dis.place="above") => nil,
    %(shape="TAB") => nil
  }.each do |attributes, name_key|
    it "reads #{attributes} as #{name_key.inspect}" do
      expect(clef(attributes)&.to_sym).to eq name_key
    end
  end

  it "reads a <staffDef>'s @clef.shape and @clef.line" do
    expect(staff_def_clef(%(<staffDef n="1" clef.shape="F" clef.line="4"/>))).to eq :bass_clef
  end

  it "prefers a <clef> child" do
    expect(staff_def_clef(%(<staffDef n="1" clef.shape="F" clef.line="4"><clef shape="C" line="3"/></staffDef>))).to eq :alto_clef
  end

  it "reads nothing from a staff definition that states no clef" do
    expect(staff_def_clef(%(<staffDef n="1"/>))).to be_nil
  end
end
