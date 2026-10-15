require "spec_helper"

describe HeadMusic::MIDI::KeyOverlaps do
  def sounding(track, on, off, key: 60, channel: 0, velocity: 80)
    described_class::Sounding.new(track, channel, key, on, off, velocity)
  end

  def resolve(*soundings)
    described_class.new(soundings).events.map do |track, event|
      [track, event.is_a?(HeadMusic::MIDI::NoteOn) ? :on : :off, event.tick]
    end
  end

  it "writes a lone note as it is" do
    expect(resolve(sounding(1, 0, 480))).to eq [[1, :on, 0], [1, :off, 480]]
  end

  it "re-strikes a held key at a later onset, sounding to the later release" do
    expect(resolve(sounding(1, 0, 960), sounding(1, 240, 480))).to eq [[1, :on, 0], [1, :off, 240], [1, :on, 240], [1, :off, 960]]
  end

  it "re-strikes touching notes" do
    expect(resolve(sounding(1, 0, 480), sounding(1, 480, 960))).to eq [[1, :on, 0], [1, :off, 480], [1, :on, 480], [1, :off, 960]]
  end

  it "strikes notes that begin together once, keeping the first velocity" do
    events = described_class.new([sounding(1, 0, 480, velocity: 50), sounding(2, 0, 960, velocity: 90)]).events
    expect(events.map { |track, event| [track, event.tick, event.velocity] }).to eq [[1, 0, 50], [1, 960, 64]]
  end

  it "writes a release that meets a strike in another track in that track" do
    expect(resolve(sounding(1, 0, 960), sounding(2, 480, 720))).to eq [[1, :on, 0], [2, :off, 480], [2, :on, 480], [2, :off, 960]]
  end

  it "leaves a release that no strike meets in its own track" do
    expect(resolve(sounding(1, 0, 240), sounding(2, 480, 720))).to eq [[1, :on, 0], [1, :off, 240], [2, :on, 480], [2, :off, 720]]
  end

  it "leaves different keys alone" do
    expect(resolve(sounding(1, 0, 960), sounding(1, 240, 480, key: 62)).length).to eq 4
  end

  it "leaves one key on different channels alone" do
    expect(resolve(sounding(1, 0, 960), sounding(2, 240, 480, channel: 1))).to eq [[1, :on, 0], [1, :off, 960], [2, :on, 240], [2, :off, 480]]
  end
end
