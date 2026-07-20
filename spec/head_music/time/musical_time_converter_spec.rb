require "spec_helper"

describe HeadMusic::Time::MusicalTimeConverter do
  subject(:converter) do
    described_class.new(
      tempo_map: conductor.tempo_map,
      meter_map: conductor.meter_map,
      starting_musical_position: conductor.starting_musical_position
    )
  end

  # A default conductor supplies correctly linked maps (quarter = 120, 4/4).
  let(:conductor) { HeadMusic::Time::Conductor.new }

  describe "#musical_to_clock" do
    it "maps the starting position to zero nanoseconds" do
      clock = converter.musical_to_clock(HeadMusic::Time::MusicalPosition.new)
      expect(clock.nanoseconds).to eq 0
    end

    it "maps one beat at 120 bpm to half a second" do
      clock = converter.musical_to_clock(HeadMusic::Time::MusicalPosition.new(1, 2, 0, 0))
      expect(clock.to_seconds).to eq 0.5
    end
  end

  describe "#clock_to_musical" do
    it "maps zero nanoseconds to the starting position" do
      position = converter.clock_to_musical(HeadMusic::Time::ClockPosition.new(0))
      expect([position.bar, position.beat]).to eq [1, 1]
    end

    it "maps half a second at 120 bpm to the second beat" do
      position = converter.clock_to_musical(HeadMusic::Time::ClockPosition.new(500_000_000))
      expect([position.bar, position.beat]).to eq [1, 2]
    end
  end

  it "round-trips a musical position" do
    original = HeadMusic::Time::MusicalPosition.new(2, 3, 0, 0)
    result = converter.clock_to_musical(converter.musical_to_clock(original))
    expect([result.bar, result.beat]).to eq [2, 3]
  end
end
