require "spec_helper"

describe HeadMusic::Notation::MEI::DynamReader do
  def read(*items, **options)
    stub_const("HeadMusic::Notation::MEI::MARK_READERS", [described_class])
    HeadMusic::Notation::MEI.parse(mei_document(*items, **options))
  end

  def dynamics_of(flow)
    flow.parts.map do |part|
      [part.dynamic_events.map(&:to_s), part.voices.map { |voice| voice.dynamic_events.map(&:to_s) }]
    end
  end

  def note_dynamics_of(flow)
    flow.voices.map { |voice| voice.voice_events.map { |event| event.note_dynamic&.name_key } }
  end

  let(:four_quarters) { mei_staff(1, mei_note("C4", "4", "xml:id": "n1") + mei_note("D4") + mei_rest("4", "xml:id": "r1") + mei_note("F4")) }

  it "places a level by beat on the part when it names no layer" do
    flow = read(four_quarters + %(<dynam staff="1" tstamp="3">f</dynam>))
    expect(dynamics_of(flow)).to eq [[["f at 1:3:000"], [[]]]]
  end

  it "places a level on the voice its layer names" do
    flow = read(four_quarters + %(<dynam staff="1" layer="1" tstamp="2">pp</dynam>))
    expect(dynamics_of(flow)).to eq [[[], [["pp at 1:2:000"]]]]
  end

  it "places a level at the note its startid names" do
    flow = read(four_quarters + %(<dynam startid="#r1" tstamp="1">mp</dynam>))
    expect(dynamics_of(flow)).to eq [[["mp at 1:3:000"], [[]]]]
  end

  it "reads a level through its text's markup" do
    flow = read(four_quarters + %(<dynam staff="1" tstamp="1"><rend fontstyle="italic"> ff </rend></dynam>))
    expect(dynamics_of(flow)).to eq [[["ff at 1:1:000"], [[]]]]
  end

  it "keeps the first of two levels at a position" do
    flow = read(four_quarters + %(<dynam staff="1" tstamp="1">p</dynam><dynam staff="1" tstamp="1">f</dynam>))
    expect(dynamics_of(flow)).to eq [[["p at 1:1:000"], [[]]]]
  end

  it "skips text that names no dynamic" do
    flow = read(four_quarters + %(<dynam staff="1" tstamp="1">cresc.</dynam><dynam staff="1" tstamp="2">p dolce</dynam><dynam staff="1"/><dynam staff="1" tstamp="4">mf</dynam>))
    expect([dynamics_of(flow), note_dynamics_of(flow)]).to eq [[[["mf at 1:4:000"], [[]]]], [[nil, nil, nil, nil]]]
  end

  it "makes an accent at a note that note's dynamic, not a level" do
    flow = read(four_quarters + %(<dynam startid="#n1">sfz</dynam>))
    expect([dynamics_of(flow), note_dynamics_of(flow)]).to eq [[[[], [[]]]], [["sfz", nil, nil, nil]]]
  end

  it "keeps the first accent at a note" do
    flow = read(four_quarters + %(<dynam startid="#n1">fp</dynam><dynam startid="#n1">sf</dynam>))
    expect(note_dynamics_of(flow)).to eq [["fp", nil, nil, nil]]
  end

  it "skips an accent at a rest" do
    flow = read(four_quarters + %(<dynam startid="#r1">sf</dynam><dynam startid="#n1">sfz</dynam>))
    expect(note_dynamics_of(flow)).to eq [["sfz", nil, nil, nil]]
  end

  it "skips an accent at a grace note rather than giving it to the main note" do
    bar = mei_staff(1, %(<note pname="d" oct="4" dur="16" grace="unacc" xml:id="g1"/>) + mei_note("C4", "1", "xml:id": "m1"))
    flow = read(bar + %(<dynam startid="#g1">sfz</dynam><dynam startid="#m1">sf</dynam>))
    expect(note_dynamics_of(flow)).to eq [["sf"]]
  end

  it "skips an accent at a tie's later link" do
    bars = [mei_staff(1, mei_note("C4", "1", tie: "i")), mei_staff(1, mei_note("C4", "2", tie: "t", "xml:id": "t1") + mei_note("D4", "2", "xml:id": "d1")) + %(<dynam startid="#t1">sfz</dynam><dynam startid="#d1">sf</dynam>)]
    expect(note_dynamics_of(read(*bars))).to eq [[nil, "sf"]]
  end

  %w[articulations_ornaments_dynamics piano_part_marks hairpins].each do |name|
    it "reads back the levels and note dynamics of the #{name} golden" do
      flow = HeadMusic::Notation::MEI.parse(File.read(MEIFixtures.path(name)))
      source = MEIFixtures.source(name)
      expect([dynamics_of(flow), note_dynamics_of(flow)]).to eq [dynamics_of(source), note_dynamics_of(source)]
    end
  end
end
