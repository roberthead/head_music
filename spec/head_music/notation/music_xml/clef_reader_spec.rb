require "spec_helper"

describe HeadMusic::Notation::MusicXML::ClefReader do
  def clef(sign, line = nil, octave_change = nil)
    xml = "<clef><sign>#{sign}</sign>#{line && "<line>#{line}</line>"}" \
      "#{octave_change && "<clef-octave-change>#{octave_change}</clef-octave-change>"}</clef>"
    described_class.clef(REXML::Document.new(xml).root)&.name_key&.to_sym
  end

  {
    %w[G 2] => :treble_clef,
    %w[F 4] => :bass_clef,
    %w[C 3] => :alto_clef,
    %w[C 4] => :tenor_clef,
    %w[G 1] => :french_violin_clef
  }.each do |(sign, line), name_key|
    it "reads #{sign} on line #{line} as the #{name_key}" do
      expect(clef(sign, line)).to eq name_key
    end
  end

  it "reads an octave change" do
    expect(clef("G", 2, -1)).to eq :vocal_tenor_clef
  end

  def read_back(clef)
    flow = HeadMusic::Content::Flow.new
    flow.add_part(staff_system: HeadMusic::Content::StaffSystem.single_staff(clef: clef)).add_voice.place("1:1", :whole, "C4")
    HeadMusic::Notation::MusicXML.parse(HeadMusic::Notation::MusicXML.render(flow)).parts.first.staff_system.first_staff.clef
  end

  it "reads back every clef the writer writes, but the double treble clef, as itself" do
    clefs = HeadMusic::Rudiment::Clef::RECORDS.filter_map { |record| record[:pitch] && HeadMusic::Rudiment::Clef.get(record[:name_key]) }
    expect(clefs.reject { |clef| read_back(clef) == clef }.map(&:name_key)).to eq ["double_treble_clef"]
  end

  it "reads a percussion clef as no clef" do
    expect(clef("percussion")).to be_nil
  end

  it "reads a clef the catalog lacks as no clef" do
    expect(clef("G", 2, 1)).to be_nil
  end
end
