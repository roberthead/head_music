require "spec_helper"

describe HeadMusic::Content::Flow::TimelineTempos do
  subject(:tempos) { described_class.new(tempo(120)) }

  def tempo(beats_per_minute, **)
    HeadMusic::Rudiment::Tempo.new("quarter", beats_per_minute, **)
  end

  # Steps fall on downbeats; ramps and a tempo points take a flow's positions.
  def position(*args)
    HeadMusic::Time::MusicalPosition.new(*args)
  end

  def flow_position(code)
    HeadMusic::Content::Flow.new.position(code)
  end

  def add_ramp(from, to, **)
    tempos.add_tempo_ramp(from: flow_position(from), to: flow_position(to), **)
  end

  def add_a_tempo(at)
    tempos.add_a_tempo(flow_position(at))
  end

  def bpm_at(*at)
    tempos.at(position(*at)).beats_per_minute
  end

  it "opens at a quarter note of 120 by default" do
    opening = described_class.new.opening_tempo
    expect([opening.beat_value.to_s, opening.beats_per_minute]).to eq ["quarter", 120]
  end

  it "reads a tempo given by name" do
    expect(described_class.new("quarter = 72").opening_tempo.beats_per_minute).to eq 72
  end

  it "answers its opening tempo where nothing has changed" do
    expect(bpm_at(5)).to eq 120
  end

  it "answers a step change from its position on" do
    tempos.change(position(3), tempo(90))
    expect([bpm_at(2), bpm_at(3), bpm_at(9)]).to eq [120, 90, 90]
  end

  it "answers the start tempo inside a ramp and its target from its end" do
    add_ramp("3:1", "5:1", to_tempo: tempo(60))
    expect([bpm_at(4), bpm_at(5)]).to eq [120, 60]
  end

  it "takes a ramp's target from the step change where it ends" do
    tempos.change(position(5), tempo(72))
    add_ramp("3:1", "5:1")
    expect(tempos.resolved_ramps.first.to_tempo.beats_per_minute).to eq 72
  end

  it "defaults a ramp's target from its text" do
    add_ramp("3:1", "5:1", text: "accel.")
    expect(tempos.resolved_ramps.first.to_tempo.beats_per_minute).to eq 160
  end

  it "restores the tempo the latest ramp began from at an a tempo" do
    add_ramp("3:1", "5:1", to_tempo: tempo(60))
    add_a_tempo("7:2")
    expect([bpm_at(7), bpm_at(7, 2)]).to eq [60, 120]
  end

  it "re-resolves after a change" do
    add_ramp("3:1", "5:1", to_tempo: tempo(60))
    bpm_at(9)
    tempos.remove_tempo_ramp(flow_position("3:1"))
    expect(bpm_at(9)).to eq 120
  end

  it "refuses a step change strictly inside a ramp" do
    add_ramp("3:1", "5:1")
    expect { tempos.change(position(4), tempo(90)) }
      .to raise_error(ArgumentError, "a tempo change at bar 4 falls inside the tempo ramp from 3:1:000 to 5:1:000")
  end

  it "refuses a ramp around a step change" do
    tempos.change(position(4), tempo(90))
    expect { add_ramp("3:1", "5:1") }.to raise_error(ArgumentError, /would hold the tempo set at 4:1:0:0/)
  end

  it "maps a ramp's target among the step changes" do
    tempos.change(position(2), tempo(90))
    add_ramp("3:1", "5:1", to_tempo: tempo(60))
    expect(tempos.authored_map.events.map { |event| [event.position.to_s, event.value.beats_per_minute] })
      .to eq [["2:1:0:0", 90], ["5:1:0:0", 60]]
  end

  it "lets a step change win over a ramp's target where it ends" do
    tempos.change(position(5), tempo(72))
    add_ramp("3:1", "5:1", to_tempo: tempo(60))
    expect(tempos.authored_map.events.map { |event| event.value.beats_per_minute }).to eq [72]
  end
end
