require "spec_helper"

describe HeadMusic::Notation::MEI::TempoMarkReader do
  def read(*items, **options)
    HeadMusic::Notation::MEI.parse(mei_document(*items, **options))
  end

  def ramps(flow)
    flow.tempo_ramps.map { |ramp| [ramp.from.to_s, ramp.to.to_s, ramp.to_tempo&.beats_per_minute, ramp.text] }
  end

  let(:bar) { mei_staff(1, mei_note("C4") + mei_note("D4", "4", "xml:id": "d") + mei_note("E4") + mei_note("F4")) }
  let(:next_bar) { mei_staff(1, mei_note("G4", "4", "xml:id": "g") + mei_note("A4", "2", dots: "1")) }

  it "reads a <tempo func=\"continuous\"> as a ramp to its @tstamp2, toward the numbered tempo there" do
    flow = read(%(#{bar}<tempo func="continuous" tstamp="3" tstamp2="1m+1" staff="1">rit.</tempo>), %(#{next_bar}<tempo tstamp="1" mm="80"/>))
    expect([ramps(flow), flow.tempo_at(2).beats_per_minute]).to eq [[["1:3:000", "2:1:000", 80.0, "rit."]], 80.0]
  end

  it "reads a ramp's end from its @endid" do
    flow = read(%(#{bar}<tempo func="continuous" startid="#d" endid="#g" staff="1">accel.</tempo>), next_bar)
    expect(ramps(flow)).to eq [["1:2:000", "2:1:000", nil, "accel."]]
  end

  it "keeps a ramp's text whatever it says, and none where it has none" do
    flow = read(
      %(#{bar}<tempo func="continuous" tstamp="1" tstamp2="0m+3" staff="1">poco a poco più mosso</tempo>),
      %(#{next_bar}<tempo func="continuous" tstamp="2" tstamp2="0m+4" staff="1"/>)
    )
    expect(ramps(flow).map(&:last)).to eq ["poco a poco più mosso", nil]
  end

  it "ends a ramp with no end at the next tempo, as a ramp word does" do
    flow = read(%(#{bar}<tempo func="continuous" tstamp="3" staff="1">rall.</tempo>), %(#{next_bar}<tempo tstamp="1" mm="72"/>))
    expect(ramps(flow)).to eq [["1:3:000", "2:1:000", 72.0, "rall."]]
  end

  it "reads ramp words in a plain <tempo> as a ramp, and \"a tempo\" as an \"a tempo\" point" do
    flow = read(%(#{bar}<tempo tstamp="2" staff="1">rit.</tempo><tempo tstamp="4" staff="1">a tempo</tempo>), next_bar)
    expect([ramps(flow), flow.a_tempos.map { |a_tempo| [a_tempo.position.to_s, a_tempo.text] }])
      .to eq [[["1:2:000", "1:4:000", nil, "rit."]], [["1:4:000", "a tempo"]]]
  end

  it "reads tempo text at a later downbeat as a tempo change with no metronome mark" do
    tempo = read(bar, %(#{next_bar}<tempo tstamp="1" staff="1"><rend fontstyle="italic">Più mosso</rend></tempo>)).tempo_changes[2]
    expect([tempo.text, tempo.metronome_mark?]).to eq ["Più mosso", false]
  end

  it "reads a tempo with neither @tstamp nor @startid at its measure's downbeat" do
    expect(read(bar, %(#{next_bar}<tempo mm="66"/>)).tempo_at(2).beats_per_minute).to eq 66.0
  end

  it "drops a ramp the timeline refuses, as one overlapping another" do
    flow = read(
      %(#{bar}<tempo func="continuous" tstamp="1" tstamp2="1m+1" staff="1">rit.</tempo><tempo func="continuous" tstamp="3" tstamp2="1m+3" staff="1">accel.</tempo>),
      next_bar
    )
    expect(ramps(flow)).to eq [["1:1:000", "2:1:000", nil, "rit."]]
  end

  it "ends a ramp word at a fermata" do
    flow = read(%(#{bar}<tempo tstamp="1" staff="1">rit.</tempo><fermata staff="1" tstamp="4"/>), next_bar)
    expect(ramps(flow)).to eq [["1:1:000", "1:4:000", nil, "rit."]]
  end
end
