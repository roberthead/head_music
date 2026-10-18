require "spec_helper"

describe HeadMusic::Notation::MusicXML::PartStaves do
  subject(:staves) { described_class.new }

  def read(xml)
    REXML::Document.new(xml).root
  end

  def attributes(xml)
    HeadMusic::Notation::MusicXML::AttributesReader.read(read("<attributes>#{xml}</attributes>"))
  end

  def note(xml)
    HeadMusic::Notation::MusicXML::NoteReader.read(read("<note>#{xml}<duration>4</duration></note>"))
  end

  let(:c4) { "<pitch><step>C</step><octave>4</octave></pitch>" }
  let(:b_flat_clarinet) { "<transpose><diatonic>-1</diatonic><chromatic>-2</chromatic></transpose>" }

  it "keeps the most staves the part ever has, and the first symbol joining them" do
    staves.change(attributes("<staves>3</staves><part-symbol>bracket</part-symbol>"))
    staves.change(attributes("<staves>2</staves><part-symbol>brace</part-symbol>"))
    expect([staves.most, staves.part_symbol]).to eq [3, "bracket"]
  end

  it "answers a note's staff, the first where it names none" do
    staves.change(attributes("<staves>2</staves>"))
    expect([staves.staff(note("#{c4}<staff>2</staff>")), staves.staff(note(c4))]).to eq [2, 1]
  end

  it "refuses a staff beyond the part's staves, naming where" do
    expect { staves.staff(note("#{c4}<staff>2</staff>"), measure: "4", part: "P1") }
      .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /beyond the part's 1 staves \(measure 4 of part P1\)/)
  end

  it "sounds a written pitch where the transposition puts it" do
    staves.change(attributes(b_flat_clarinet))
    expect(staves.sound(note(c4)).to_s).to eq "B♭3"
  end

  it "lands a transposing part's key in concert pitch" do
    staves.change(attributes(b_flat_clarinet))
    expect(staves.concert_key([0, "major"])).to eq [-2, "major"]
  end

  it "sounds an unpitched note as an unpitched sound" do
    expect(staves.sound(note("<unpitched/>"))).to be_a HeadMusic::Rudiment::UnpitchedSound
  end
end
