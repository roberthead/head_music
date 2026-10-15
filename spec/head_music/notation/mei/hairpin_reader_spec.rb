require "spec_helper"

describe HeadMusic::Notation::MEI::HairpinReader do
  def read(*items, **options)
    stub_const("HeadMusic::Notation::MEI::MARK_READERS", [described_class])
    HeadMusic::Notation::MEI.parse(mei_document(*items, **options))
  end

  def hairpins_of(flow)
    flow.parts.map do |part|
      [hairpin_strings(part), part.voices.map { |voice| hairpin_strings(voice) }]
    end
  end

  def hairpin_strings(owner)
    owner.spans.select(&:hairpin?).map(&:to_s)
  end

  let(:four_quarters) { mei_staff(1, mei_note("C4", "4", "xml:id": "n1") + mei_note("D4") + mei_note("E4", "4", "xml:id": "n3") + mei_note("F4")) }

  it "reads a crescendo by beats onto the part when it names no layer" do
    flow = read(four_quarters + %(<hairpin form="cres" staff="1" tstamp="1" tstamp2="0m+3"/>))
    expect(hairpins_of(flow)).to eq [[["crescendo from 1:1:000 to 1:3:000"], [[]]]]
  end

  it "reads a diminuendo onto the voice its layer names" do
    flow = read(four_quarters + %(<hairpin form="dim" staff="1" layer="1" tstamp="2" tstamp2="0m+4"/>))
    expect(hairpins_of(flow)).to eq [[[], [["diminuendo from 1:2:000 to 1:4:000"]]]]
  end

  it "takes ids over beats" do
    flow = read(four_quarters + %(<hairpin form="cres" staff="1" startid="#n1" endid="#n3" tstamp="2" tstamp2="0m+4"/>))
    expect(hairpins_of(flow)).to eq [[["crescendo from 1:1:000 to 1:3:000"], [[]]]]
  end

  it "reads one ending past the last bar's count as running to the final barline" do
    flow = read(four_quarters, mei_staff(1, mei_note("G4", "1")) + %(<hairpin form="dim" staff="1" tstamp="1" tstamp2="0m+5"/>))
    expect(hairpins_of(flow)).to eq [[["diminuendo from 2:1:000 to 3:1:000"], [[]]]]
  end

  it "drops a hairpin with no end" do
    controls = %(<hairpin form="cres" staff="1" tstamp="1"/><hairpin form="cres" staff="1" tstamp="1" tstamp2="3"/><hairpin form="dim" staff="1" tstamp="3" tstamp2="0m+4"/>)
    expect(hairpins_of(read(four_quarters + controls))).to eq [[["diminuendo from 1:3:000 to 1:4:000"], [[]]]]
  end

  it "skips a hairpin with no form it knows" do
    controls = %(<hairpin staff="1" tstamp="1" tstamp2="0m+3"/><hairpin form="swell" staff="1" tstamp="1" tstamp2="0m+3"/><hairpin form="dim" staff="1" tstamp="3" tstamp2="0m+4"/>)
    expect(hairpins_of(read(four_quarters + controls))).to eq [[["diminuendo from 1:3:000 to 1:4:000"], [[]]]]
  end

  it "drops a hairpin its owner refuses, as one overlapping the one before" do
    controls = %(<hairpin form="cres" staff="1" tstamp="1" tstamp2="0m+3"/><hairpin form="dim" staff="1" tstamp="2" tstamp2="0m+4"/>)
    expect(hairpins_of(read(four_quarters + controls))).to eq [[["crescendo from 1:1:000 to 1:3:000"], [[]]]]
  end

  %w[hairpins piano_part_marks].each do |name|
    it "reads back the hairpins of the #{name} golden" do
      flow = HeadMusic::Notation::MEI.parse(File.read(MEIFixtures.path(name)))
      expect(hairpins_of(flow)).to eq hairpins_of(MEIFixtures.source(name))
    end
  end

  HairpinGenerator::SEEDS.each do |seed|
    it "round-trips the hairpins of seed #{seed}" do
      source = HairpinGenerator.flow(seed)
      expect(hairpins_of(HeadMusic::Notation::MEI.parse(source.to_mei))).to eq(hairpins_of(source)), "seed #{seed}"
    end
  end
end
