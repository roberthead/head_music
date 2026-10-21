require "spec_helper"

describe HeadMusic::Notation::MEI::DownbeatTempo do
  let(:measure) do
    REXML::Document.new(%(<measure><note xml:id="first"/><chord xml:id="later"><note xml:id="tone"/></chord></measure>)).root
  end
  let(:first_note) { measure.elements[1] }
  let(:later_chord) { measure.elements[2] }
  let(:entries) do
    [
      HeadMusic::Notation::MEI::LayerReader::Entry.new(kind: :note, element: first_note, notes: [first_note], cursor: 0, grace: false),
      HeadMusic::Notation::MEI::LayerReader::Entry.new(kind: :chord, element: later_chord, notes: later_chord.elements.to_a, cursor: Rational(1, 2), grace: false)
    ]
  end
  let(:index) do
    HeadMusic::Notation::MEI::IdIndex.new.tap do |index|
      REXML::XPath.each(measure, "//*[@xml:id]") do |element|
        index.register(element.attributes["xml:id"], element)
        index.reach(element)
      end
    end
  end
  let(:meter) { HeadMusic::Rudiment::Meter.get("4/4") }
  let(:editorial) { HeadMusic::Notation::MEI::Editorial.new(index, budget: 10) }

  def tempo(*xml)
    controls = xml.map { |control| REXML::Document.new(control).root }
    described_class.tempo(controls, entries, meter, index, editorial, measure: "1")&.beats_per_minute
  end

  it "reads a <tempo> on the downbeat by @tstamp, or at a beat before the first" do
    expect([tempo(%(<tempo tstamp="1" midi.bpm="88"/>)), tempo(%(<tempo tstamp="0" midi.bpm="66"/>))]).to eq [88.0, 66.0]
  end

  it "reads a <tempo> whose @startid names an entry starting the measure, and one with neither" do
    expect([tempo(%(<tempo startid="#first" midi.bpm="88"/>)), tempo(%(<tempo midi.bpm="66"/>))]).to eq [88.0, 66.0]
  end

  it "skips a <tempo> later in the bar, by @tstamp or @startid, for the next on the downbeat" do
    expect(tempo(%(<tempo tstamp="3" midi.bpm="88"/>), %(<tempo startid="#tone" midi.bpm="66"/>), %(<tempo tstamp="1" mm="72"/>))).to eq 72.0
  end

  it "reads a <tempo> with text only at the number its words name" do
    expect(tempo(%(<tempo tstamp="1">Adagio</tempo>))).to eq 60.0
  end

  it "skips a gradual change, ramp and \"a tempo\" words alone, and every other control" do
    skipped = [
      %(<tempo tstamp="1" func="continuous" tstamp2="1m+1" midi.bpm="60">rit.</tempo>), %(<tempo tstamp="1">rall.</tempo>),
      %(<tempo tstamp="1">a tempo</tempo>), %(<dynam tstamp="1" midi.bpm="88">p</dynam>)
    ]
    expect(tempo(*skipped)).to be_nil
  end
end
