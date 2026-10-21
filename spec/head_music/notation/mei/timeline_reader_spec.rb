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

  it "changes the tempo at a <tempo> whose @startid names a note at the measure's first onset, and not one later" do
    notes = mei_staff(1, mei_note("C4", "2", "xml:id": "first") + %(<chord dur="2"><note xml:id="later" pname="e" oct="4"/></chord>))
    flow = parse(bar, notes + %(<tempo startid="#first" midi.bpm="88"/>), notes.gsub(/first|later/) { "#{_1}2" } + %(<tempo startid="#later2" midi.bpm="66"/>))
    expect(tempos(flow)).to eq(2 => ["quarter", 88.0])
  end

  it "reads @midi.bpm in quarters where there is no @mm" do
    expect(tempos(parse(bar, %(#{bar}<tempo tstamp="1" midi.bpm="88"/>)))).to eq(2 => ["quarter", 88.0])
  end

  it "skips a tempo in the middle of a bar" do
    expect(tempos(parse(bar, %(#{bar}<tempo tstamp="3" midi.bpm="88"/>)))).to be_empty
  end

  it "skips a tempo in the second half of a split bar, though it starts its measure" do
    half = mei_staff(1, mei_note("C4", "2"))
    flow = parse(bar, %(<measure n="2" metcon="false">#{half}</measure>), %(<measure n="3" metcon="false">#{half}<tempo midi.bpm="88"/></measure>))
    expect(tempos(flow)).to be_empty
  end

  it "reads a tempo of text alone as that text, with the number its words name and no metronome mark" do
    tempo = parse(bar, %(#{bar}<tempo tstamp="1">Andante</tempo>)).tempo_at(2)
    expect([tempo.text, tempo.beats_per_minute, tempo.metronome_mark?]).to eq ["Andante", 78.0, false]
  end

  it "reads the opening tempo's text, nested in <rend>" do
    tempo = parse(%(#{bar}<tempo tstamp="1" mm="96"><rend fontstyle="italic">Allegro</rend> moderato</tempo>)).tempo
    expect([tempo.text, tempo.beats_per_minute, tempo.metronome_mark?]).to eq ["Allegro moderato", 96.0, true]
  end

  it "reads a tempo of words alone at its @midi.bpm where that differs from what its words name" do
    tempo = parse(%(#{bar}<tempo tstamp="1" midi.bpm="100">Allegro</tempo>)).tempo
    expect([tempo.text, tempo.beats_per_minute, tempo.metronome_mark?]).to eq ["Allegro", 100.0, false]
  end

  it "opens with a tempo on the first downbeat over the scoreDef's" do
    expect(parse(%(#{bar}<tempo tstamp="1" mm="72"/>)).tempo.beats_per_minute).to eq 72.0
  end

  it "makes no change for a tempo restated" do
    flow = parse(bar, %(#{bar}<tempo tstamp="1" midi.bpm="88"/>), %(#{bar}<tempo tstamp="1" midi.bpm="88"/>))
    expect(tempos(flow).keys).to eq [2]
  end

  it "changes the meter where only its symbol changes" do
    flow = parse(bar, %(<scoreDef meter.count="4" meter.unit="4" meter.sym="common"/>), bar, %(<scoreDef meter.count="4" meter.unit="4" meter.sym="common"/>), bar)
    expect(flow.meter_changes.transform_values(&:symbol)).to eq(2 => :common)
  end

  it "makes no key change for a restatement" do
    flow = parse(bar, %(<scoreDef keysig="0"/>), bar, score_def: mei_score_def(keysig: "0"))
    expect(flow.key_signature_changes).to be_empty
  end
end
