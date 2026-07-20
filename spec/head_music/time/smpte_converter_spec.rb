require "spec_helper"

describe HeadMusic::Time::SmpteConverter do
  subject(:converter) do
    described_class.new(framerate: framerate, starting_smpte_timecode: starting)
  end

  let(:framerate) { 30 }
  let(:starting) { HeadMusic::Time::SmpteTimecode.new(0, 0, 0, 0, framerate: framerate) }

  describe "#clock_to_smpte" do
    it "converts 0 nanoseconds to the starting timecode" do
      smpte = converter.clock_to_smpte(HeadMusic::Time::ClockPosition.new(0))
      expect(smpte.to_s).to eq "00:00:00:00"
    end

    it "converts one second to one second of frames" do
      smpte = converter.clock_to_smpte(HeadMusic::Time::ClockPosition.new(1_000_000_000))
      expect(smpte.to_s).to eq "00:00:01:00"
    end

    context "with a nonzero starting timecode" do
      let(:starting) { HeadMusic::Time::SmpteTimecode.new(0, 0, 10, 0, framerate: framerate) }

      it "offsets from the starting timecode" do
        smpte = converter.clock_to_smpte(HeadMusic::Time::ClockPosition.new(0))
        expect(smpte.to_s).to eq "00:00:10:00"
      end
    end
  end

  describe "#smpte_to_clock" do
    it "converts the starting timecode to zero nanoseconds" do
      clock = converter.smpte_to_clock(starting)
      expect(clock.nanoseconds).to eq 0
    end

    it "converts one second of timecode to one second of clock time" do
      smpte = HeadMusic::Time::SmpteTimecode.new(0, 0, 1, 0, framerate: framerate)
      expect(converter.smpte_to_clock(smpte).to_seconds).to eq 1.0
    end
  end

  it "round-trips a clock position" do
    original = HeadMusic::Time::ClockPosition.new(5_000_000_000)
    round_tripped = converter.smpte_to_clock(converter.clock_to_smpte(original))
    expect(round_tripped.nanoseconds).to eq original.nanoseconds
  end
end
