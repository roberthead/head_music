require "spec_helper"

describe HeadMusic::Notation::MEI::TimelineReader do
  def parse(*items, **options)
    HeadMusic::Notation::MEI.parse(mei_document(*items, **options))
  end

  def tempos(flow)
    flow.tempo_changes.transform_values { |tempo| [tempo.beat_value.to_s, tempo.beats_per_minute] }
  end

  let(:bar) { mei_staff(1, mei_note("C4", "1")) }

  it "changes the tempo at a downbeat <tempo> by @mm in its unit" do
    flow = parse(bar, %(#{bar}<tempo tstamp="1" staff="1" mm="60" mm.unit="4" mm.dots="1" midi.bpm="90"/>))
    expect(tempos(flow)).to eq(2 => ["dotted quarter", 60.0])
  end

  it "takes a <tempo> at a beat before the first, as 0, as on the downbeat" do
    expect(tempos(parse(bar, %(#{bar}<tempo tstamp="0" midi.bpm="88"/>)))).to eq(2 => ["quarter", 88.0])
  end

  it "reads @midi.bpm in quarters where there is no @mm" do
    expect(tempos(parse(bar, %(#{bar}<tempo tstamp="1" midi.bpm="88"/>)))).to eq(2 => ["quarter", 88.0])
  end

  it "skips a tempo in the middle of a bar, and one with text only" do
    flow = parse(bar, %(#{bar}<tempo tstamp="3" midi.bpm="88"/>), %(#{bar}<tempo tstamp="1">Allegro</tempo>))
    expect(tempos(flow)).to be_empty
  end

  it "opens with a tempo on the first downbeat over the scoreDef's" do
    expect(parse(%(#{bar}<tempo tstamp="1" mm="72"/>)).tempo.beats_per_minute).to eq 72.0
  end

  it "makes no change for a tempo restated" do
    flow = parse(bar, %(#{bar}<tempo tstamp="1" midi.bpm="88"/>), %(#{bar}<tempo tstamp="1" midi.bpm="88"/>))
    expect(tempos(flow).keys).to eq [2]
  end

  it "makes no key change for a restatement" do
    flow = parse(bar, %(<scoreDef keysig="0"/>), bar, score_def: mei_score_def(keysig: "0"))
    expect(flow.key_signature_changes).to be_empty
  end
end
