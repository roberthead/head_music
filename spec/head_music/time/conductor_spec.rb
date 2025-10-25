require "spec_helper"

describe HeadMusic::Time::Conductor do
  describe "#initialize" do
    context "with default parameters" do
      subject(:conductor) { described_class.new }

      it "initializes with default starting position" do
        expect(conductor.starting_musical_position).to be_a(HeadMusic::Time::MusicalPosition)
        expect(conductor.starting_musical_position.to_s).to eq "1:1:0:0"
      end

      it "initializes with default starting timecode" do
        expect(conductor.starting_smpte_timecode).to be_a(HeadMusic::Time::SmpteTimecode)
        expect(conductor.starting_smpte_timecode.to_s).to eq "00:00:00:00"
      end

      it "initializes with default framerate" do
        expect(conductor.framerate).to eq 30
      end

      it "initializes with default tempo" do
        expect(conductor.starting_tempo).to be_a(HeadMusic::Rudiment::Tempo)
        expect(conductor.starting_tempo.beats_per_minute).to eq 120.0
      end

      it "initializes with default meter" do
        expect(conductor.starting_meter).to be_a(HeadMusic::Rudiment::Meter)
        expect(conductor.starting_meter.to_s).to eq "4/4"
      end
    end

    context "with custom parameters" do
      subject(:conductor) do
        described_class.new(
          starting_musical_position: HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0),
          starting_smpte_timecode: HeadMusic::Time::SmpteTimecode.new(1, 0, 0, 0),
          framerate: 24,
          starting_tempo: HeadMusic::Rudiment::Tempo.new("quarter", 96),
          starting_meter: HeadMusic::Rudiment::Meter.get("3/4")
        )
      end

      its(:starting_musical_position) { is_expected.to have_attributes(bar: 5) }
      its(:starting_smpte_timecode) { is_expected.to have_attributes(hour: 1) }
      its(:framerate) { is_expected.to eq 24 }
      its(:starting_tempo) { is_expected.to have_attributes(beats_per_minute: 96.0) }
      its(:starting_meter) { is_expected.to have_attributes(to_s: "3/4") }
    end
  end

  describe "#clock_to_musical" do
    subject(:conductor) { described_class.new }

    context "with tempo quarter = 120" do
      it "converts 0 nanoseconds to position 1:1:0:0" do
        clock_pos = HeadMusic::Time::ClockPosition.new(0)
        musical_pos = conductor.clock_to_musical(clock_pos)
        expect(musical_pos.to_s).to eq "1:1:0:0"
      end

      it "converts 500ms (one beat at 120 bpm) to position 1:2:0:0" do
        clock_pos = HeadMusic::Time::ClockPosition.new(500_000_000)
        musical_pos = conductor.clock_to_musical(clock_pos)
        expect(musical_pos.to_s).to eq "1:2:0:0"
      end

      it "converts 2 seconds (4 beats) to position 2:1:0:0 in 4/4" do
        clock_pos = HeadMusic::Time::ClockPosition.new(2_000_000_000)
        musical_pos = conductor.clock_to_musical(clock_pos)
        expect(musical_pos.to_s).to eq "2:1:0:0"
      end

      it "handles fractional tick values" do
        # 250ms = half a beat = 480 ticks
        clock_pos = HeadMusic::Time::ClockPosition.new(250_000_000)
        musical_pos = conductor.clock_to_musical(clock_pos)
        expect(musical_pos.bar).to eq 1
        expect(musical_pos.beat).to eq 1
        expect(musical_pos.tick).to eq 480
      end
    end

    context "with different tempo" do
      subject(:conductor) do
        described_class.new(
          starting_tempo: HeadMusic::Rudiment::Tempo.new("quarter", 60)
        )
      end

      it "converts 1 second (one beat at 60 bpm) to position 1:2:0:0" do
        clock_pos = HeadMusic::Time::ClockPosition.new(1_000_000_000)
        musical_pos = conductor.clock_to_musical(clock_pos)
        expect(musical_pos.to_s).to eq "1:2:0:0"
      end
    end
  end

  describe "#musical_to_clock" do
    subject(:conductor) { described_class.new }

    context "with tempo quarter = 120" do
      it "converts position 1:1:0:0 to 0 nanoseconds" do
        musical_pos = HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0)
        clock_pos = conductor.musical_to_clock(musical_pos)
        expect(clock_pos.nanoseconds).to eq 0
      end

      it "converts position 1:2:0:0 to 500ms" do
        musical_pos = HeadMusic::Time::MusicalPosition.new(1, 2, 0, 0)
        clock_pos = conductor.musical_to_clock(musical_pos)
        expect(clock_pos.to_milliseconds).to eq 500.0
      end

      it "converts position 2:1:0:0 to 2 seconds in 4/4" do
        musical_pos = HeadMusic::Time::MusicalPosition.new(2, 1, 0, 0)
        clock_pos = conductor.musical_to_clock(musical_pos)
        expect(clock_pos.to_seconds).to eq 2.0
      end

      it "handles tick values" do
        # 480 ticks = half a beat = 250ms at 120 bpm
        musical_pos = HeadMusic::Time::MusicalPosition.new(1, 1, 480, 0)
        clock_pos = conductor.musical_to_clock(musical_pos)
        expect(clock_pos.to_milliseconds).to eq 250.0
      end
    end
  end

  describe "#clock_to_smpte" do
    subject(:conductor) { described_class.new(framerate: 30) }

    it "converts 0 nanoseconds to 00:00:00:00" do
      clock_pos = HeadMusic::Time::ClockPosition.new(0)
      smpte = conductor.clock_to_smpte(clock_pos)
      expect(smpte.to_s).to eq "00:00:00:00"
    end

    it "converts 1 second to 00:00:01:00" do
      clock_pos = HeadMusic::Time::ClockPosition.new(1_000_000_000)
      smpte = conductor.clock_to_smpte(clock_pos)
      expect(smpte.to_s).to eq "00:00:01:00"
    end

    it "converts to correct frame count at 30 fps" do
      # 1/30th of a second = 33,333,333 nanoseconds (rounds to 1 frame)
      clock_pos = HeadMusic::Time::ClockPosition.new(33_333_333)
      smpte = conductor.clock_to_smpte(clock_pos)
      expect(smpte.frame).to eq 1
      expect(smpte.second).to eq 0
    end

    it "converts one minute to 00:01:00:00" do
      clock_pos = HeadMusic::Time::ClockPosition.new(60_000_000_000)
      smpte = conductor.clock_to_smpte(clock_pos)
      expect(smpte.to_s).to eq "00:01:00:00"
    end

    context "with 24 fps framerate" do
      subject(:conductor) { described_class.new(framerate: 24) }

      it "uses 24 fps for conversions" do
        # 1 second = 24 frames at 24 fps
        clock_pos = HeadMusic::Time::ClockPosition.new(1_000_000_000)
        smpte = conductor.clock_to_smpte(clock_pos)
        expect(smpte.framerate).to eq 24
      end
    end
  end

  describe "#smpte_to_clock" do
    subject(:conductor) { described_class.new(framerate: 30) }

    it "converts 00:00:00:00 to 0 nanoseconds" do
      smpte = HeadMusic::Time::SmpteTimecode.new(0, 0, 0, 0, framerate: 30)
      clock_pos = conductor.smpte_to_clock(smpte)
      expect(clock_pos.nanoseconds).to eq 0
    end

    it "converts 00:00:01:00 to 1 second" do
      smpte = HeadMusic::Time::SmpteTimecode.new(0, 0, 1, 0, framerate: 30)
      clock_pos = conductor.smpte_to_clock(smpte)
      expect(clock_pos.to_seconds).to eq 1.0
    end

    it "converts frames to nanoseconds at 30 fps" do
      smpte = HeadMusic::Time::SmpteTimecode.new(0, 0, 0, 15, framerate: 30)
      clock_pos = conductor.smpte_to_clock(smpte)
      expect(clock_pos.to_seconds).to eq 0.5
    end

    it "converts 00:01:00:00 to one minute" do
      smpte = HeadMusic::Time::SmpteTimecode.new(0, 1, 0, 0, framerate: 30)
      clock_pos = conductor.smpte_to_clock(smpte)
      expect(clock_pos.to_seconds).to eq 60.0
    end
  end

  describe "round-trip conversions" do
    subject(:conductor) { described_class.new }

    it "converts clock -> musical -> clock" do
      original_clock = HeadMusic::Time::ClockPosition.new(1_234_567_890)
      musical = conductor.clock_to_musical(original_clock)
      result_clock = conductor.musical_to_clock(musical)

      # Should be very close (within one tick duration at 120 bpm)
      # One tick at 120 bpm = ~520,833 nanoseconds
      expect((result_clock.nanoseconds - original_clock.nanoseconds).abs).to be < 600_000
    end

    it "converts clock -> smpte -> clock" do
      original_clock = HeadMusic::Time::ClockPosition.new(5_000_000_000)
      smpte = conductor.clock_to_smpte(original_clock)
      result_clock = conductor.smpte_to_clock(smpte)

      # Should be very close (within frame rounding)
      expect((result_clock.nanoseconds - original_clock.nanoseconds).abs).to be < 50_000_000
    end

    it "converts musical -> clock -> musical" do
      original_musical = HeadMusic::Time::MusicalPosition.new(3, 2, 480, 0)
      result_musical = conductor.clock_to_musical(conductor.musical_to_clock(original_musical))

      expect(result_musical.to_a[0..2]).to eq original_musical.to_a[0..2]
    end
  end
end
