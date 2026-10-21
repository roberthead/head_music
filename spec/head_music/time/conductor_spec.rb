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
        expect(musical_pos.count).to eq 1
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

  describe "with multiple tempo changes" do
    subject(:conductor) { described_class.new }

    before do
      # Bar 1-4: 120 bpm
      # Bar 5-8: 96 bpm
      # Bar 9+: 140 bpm
      conductor.tempo_map.add_change(HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0), "quarter", 96)
      conductor.tempo_map.add_change(HeadMusic::Time::MusicalPosition.new(9, 1, 0, 0), "quarter", 140)
    end

    describe "#musical_to_clock" do
      it "calculates clock time across tempo changes" do
        # Bar 1 beat 1: start
        # 4 bars at 120 bpm = 8 seconds (0.5s per beat, 4 beats per bar = 2s per bar)
        position = HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0)
        clock = conductor.musical_to_clock(position)
        expect(clock.to_seconds).to be_within(0.01).of(8.0)
      end

      it "calculates position in second tempo segment" do
        # Bars 1-4 at 120 bpm: 8 seconds
        # Bar 5 at 96 bpm: 2.5 seconds (0.625s per beat)
        # Total: 10.5 seconds
        position = HeadMusic::Time::MusicalPosition.new(6, 1, 0, 0)
        clock = conductor.musical_to_clock(position)
        expect(clock.to_seconds).to be_within(0.01).of(10.5)
      end

      it "calculates position in third tempo segment" do
        # Bars 1-4 at 120 bpm: 8 seconds
        # Bars 5-8 at 96 bpm: 10 seconds
        # Bar 9 beat 1: 18 seconds
        position = HeadMusic::Time::MusicalPosition.new(9, 1, 0, 0)
        clock = conductor.musical_to_clock(position)
        expect(clock.to_seconds).to be_within(0.01).of(18.0)
      end
    end

    describe "#clock_to_musical" do
      it "converts clock to musical across tempo changes" do
        # 8 seconds = end of bar 4 (4 bars at 120 bpm)
        clock = HeadMusic::Time::ClockPosition.new(8_000_000_000)
        position = conductor.clock_to_musical(clock)
        expect(position.bar).to eq 5
        expect(position.count).to eq 1
      end

      it "finds position in second tempo segment" do
        # 10.5 seconds = bar 6 beat 1
        clock = HeadMusic::Time::ClockPosition.new(10_500_000_000)
        position = conductor.clock_to_musical(clock)
        expect(position.bar).to eq 6
        expect(position.count).to eq 1
      end

      it "finds position in third tempo segment" do
        # 18 seconds = bar 9 beat 1
        clock = HeadMusic::Time::ClockPosition.new(18_000_000_000)
        position = conductor.clock_to_musical(clock)
        expect(position.bar).to eq 9
        expect(position.count).to eq 1
      end
    end

    describe "round-trip with tempo changes" do
      it "maintains accuracy across tempo boundaries" do
        original_position = HeadMusic::Time::MusicalPosition.new(7, 3, 480, 0)
        result_position = conductor.clock_to_musical(conductor.musical_to_clock(original_position))
        expect(result_position).to have_attributes(bar: original_position.bar, count: original_position.count)
        expect(result_position.tick).to be_within(5).of(original_position.tick)
      end
    end
  end

  describe "with multiple meter changes" do
    subject(:conductor) { described_class.new }

    before do
      # Bar 1-4: 4/4
      # Bar 5-8: 3/4
      # Bar 9+: 6/8
      conductor.meter_map.add_change(HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0), "3/4")
      conductor.meter_map.add_change(HeadMusic::Time::MusicalPosition.new(9, 1, 0, 0), "6/8")
    end

    describe "#musical_to_clock" do
      it "calculates correctly across meter changes" do
        # Bar 1-4 in 4/4: 16 beats at 120 bpm = 8 seconds
        position = HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0)
        clock = conductor.musical_to_clock(position)
        expect(clock.to_seconds).to be_within(0.01).of(8.0)
      end

      it "counts a bar of 3/4 as three beats" do
        position = HeadMusic::Time::MusicalPosition.new(6, 1, 0, 0)
        clock = conductor.musical_to_clock(position)
        expect(clock.to_seconds).to eq 9.5
      end

      it "counts each meter's bars in the third segment" do
        # 16 beats of 4/4, 12 of 3/4, then a bar of 6/8 (two dotted-quarter counts)
        position = HeadMusic::Time::MusicalPosition.new(10, 1, 0, 0)
        expect(conductor.musical_to_clock(position).to_seconds).to eq 15.5
      end
    end

    describe "#clock_to_musical" do
      it "finds a position in the second meter segment" do
        position = conductor.clock_to_musical(HeadMusic::Time::ClockPosition.new(9_500_000_000))
        expect(position.to_a).to eq [6, 1, 0, 0]
      end

      it "finds a position past a thousand bars" do
        position = HeadMusic::Time::MusicalPosition.new(1200, 2, 0, 0)
        expect(conductor.clock_to_musical(conductor.musical_to_clock(position)).to_a).to eq position.to_a
      end
    end
  end

  describe "with both tempo and meter changes" do
    subject(:conductor) { described_class.new }

    before do
      conductor.tempo_map.add_change(HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0), "quarter", 96)
      conductor.meter_map.add_change(HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0), "3/4")
    end

    it "handles simultaneous tempo and meter changes" do
      position = HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0)
      clock = conductor.musical_to_clock(position)
      expect(clock.to_seconds).to be_within(0.01).of(8.0)
      expect(conductor.clock_to_musical(clock)).to have_attributes(bar: 5, count: 1)
    end

    it "calculates within the new meter and tempo" do
      # Bar 5 beat 2 in 3/4 at 96 bpm
      # 8 seconds + 0.625 seconds = 8.625 seconds
      position = HeadMusic::Time::MusicalPosition.new(5, 2, 0, 0)
      clock = conductor.musical_to_clock(position)
      expect(clock.to_seconds).to be_within(0.01).of(8.625)
    end
  end

  describe "#tempo_map and #meter_map access" do
    subject(:conductor) { described_class.new }

    it "provides access to tempo_map" do
      expect(conductor.tempo_map).to be_a(HeadMusic::Time::TempoMap)
    end

    it "provides access to meter_map" do
      expect(conductor.meter_map).to be_a(HeadMusic::Time::MeterMap)
    end

    it "allows adding tempo changes via tempo_map" do
      conductor.tempo_map.add_change(HeadMusic::Time::MusicalPosition.new(10, 1, 0, 0), "quarter", 80)
      expect(conductor.tempo_map.events.length).to eq 2
    end

    it "allows adding meter changes via meter_map" do
      conductor.meter_map.add_change(HeadMusic::Time::MusicalPosition.new(10, 1, 0, 0), "5/4")
      expect(conductor.meter_map.events.length).to eq 2
    end
  end

  describe "through tempo ramps and fermatas" do
    def position(*args)
      HeadMusic::Time::MusicalPosition.new(*args)
    end

    def tempo(beats_per_minute, beat_value = "quarter")
      HeadMusic::Rudiment::Tempo.new(beat_value, beats_per_minute)
    end

    def ramp(from, to, to_tempo = nil, text = nil)
      HeadMusic::Time::TempoRamp.new(from: position(*from), to: position(*to), to_tempo: to_tempo, text: text)
    end

    def fermata(from, to, stretch = 2)
      HeadMusic::Time::Fermata.new(from: position(*from), to: position(*to), stretch: stretch)
    end

    def clock(position)
      conductor.musical_to_clock(position).nanoseconds
    end

    def musical(nanoseconds)
      conductor.clock_to_musical(HeadMusic::Time::ClockPosition.new(nanoseconds)).to_a
    end

    def seconds(value)
      (value * 1_000_000_000).round
    end

    let(:tempo_ramps) { [] }
    let(:fermatas) { [] }
    let(:conductor) { described_class.new(tempo_ramps: tempo_ramps, fermatas: fermatas) }

    it "keeps its ramps and fermatas" do
      expect([conductor.tempo_ramps, conductor.fermatas]).to eq [[], []]
    end

    context "with a 4/4 bar ramping from 120 to 80" do
      let(:tempo_ramps) { [ramp([1], [2], tempo(80))] }

      it "takes (L / delta) ln(v1 / v0) for the bar" do
        expect(clock(position(2))).to eq 2_432_790_649
      end

      it "times a position inside the ramp in closed form" do
        expect(clock(position(1, 3))).to eq seconds(6 * Math.log(1.2))
      end

      it "continues at the target after the ramp" do
        expect(clock(position(3))).to eq 5_432_790_649
      end

      it "maps the ramp's clock time back to its end" do
        expect(musical(2_432_790_649)).to eq [2, 1, 0, 0]
      end

      it "maps a clock time inside the ramp back into it" do
        expect(musical(seconds(6 * Math.log(1.2)))).to eq [1, 3, 0, 0]
      end

      it "round-trips positions inside the ramp exactly" do
        positions = [position(1, 1, 1, 7), position(1, 2, 480), position(1, 4, 959, 239), position(2, 1, 0, 1)]
        expect(positions.map { |each| conductor.clock_to_musical(conductor.musical_to_clock(each)).to_a }).to eq positions.map(&:to_a)
      end

      it "round-trips clock times within one subtick" do
        slowest_subtick = 60_000_000_000.0 / (80 * 960 * HeadMusic::Time::SUBTICKS_PER_TICK)
        times = [1, 123_456_789, 1_000_000_007, 2_432_790_600]
        expect(times.map { |time| (clock(conductor.clock_to_musical(HeadMusic::Time::ClockPosition.new(time))) - time).abs })
          .to all(be <= slowest_subtick)
      end

      it "sounds the start tempo at the start" do
        expect(conductor.tempo_at(position(1))).to eq tempo(120)
      end

      it "sounds the interpolated tempo inside the ramp" do
        expect(conductor.tempo_at(position(1, 3)).beats_per_minute).to eq 100
      end

      it "sounds the target after the ramp" do
        expect(conductor.tempo_at(position(5))).to eq tempo(80)
      end
    end

    context "with a ramp whose two ends are equal" do
      let(:tempo_ramps) { [ramp([1], [2], tempo(120))] }

      it "keeps the tempo" do
        expect(clock(position(2))).to eq 2_000_000_000
      end
    end

    context "with a ramp across a meter change" do
      let(:tempo_ramps) { [ramp([1], [3], tempo(50))] }

      before { conductor.meter_map.add_change(position(2), "3/4") }

      it "ramps over each bar in its own meter" do
        expect(clock(position(3))).to eq seconds(6 * Math.log(2.4))
      end

      it "maps the end back" do
        expect(musical(seconds(6 * Math.log(2.4)))).to eq [3, 1, 0, 0]
      end
    end

    context "with a ramp between different beat values" do
      let(:tempo_ramps) { [ramp([1], [2], tempo(40, "half"))] }

      it "interpolates in whole notes per minute" do
        expect(clock(position(2))).to eq 2_432_790_649
      end

      it "sounds the tempo in the starting beat value" do
        expect(conductor.tempo_at(position(1, 3))).to have_attributes(beats_per_minute: 100, beat_value: HeadMusic::Rudiment::RhythmicValue.get("quarter"))
      end
    end

    context "with a ramp that has no target" do
      let(:tempo_ramps) { [ramp([1], [2], nil, text)] }
      let(:text) { "rit." }

      it "slows to three quarters of the start" do
        expect(conductor.tempo_at(position(3)).beats_per_minute).to eq 90
      end

      context "with accel." do
        let(:text) { "accel." }

        it "speeds up to four thirds of the start" do
          expect(conductor.tempo_at(position(3)).beats_per_minute).to eq 160
        end
      end
    end

    context "with a tempo change where a ramp ends" do
      let(:tempo_ramps) { [ramp([1], [2], tempo(80))] }

      before { conductor.tempo_map.add_change(position(2), tempo(60)) }

      it "ramps to the target and then changes" do
        expect(clock(position(3)) - clock(position(2))).to eq 4_000_000_000
      end
    end

    context "with a tempo change where a ramp starts" do
      let(:tempo_ramps) { [ramp([2], [3], tempo(40))] }

      before { conductor.tempo_map.add_change(position(2), tempo(60)) }

      it "ramps from the change" do
        expect(clock(position(3)) - clock(position(2))).to eq seconds(12 * Math.log(1.5))
      end
    end

    context "with a tempo change inside a ramp" do
      let(:tempo_ramps) { [ramp([1], [3], tempo(80))] }

      before { conductor.tempo_map.add_change(position(2), tempo(60)) }

      it "yields to the ramp already under way" do
        expect(conductor.tempo_at(position(2)).beats_per_minute).to eq 100
      end
    end

    context "with ramps that touch" do
      let(:tempo_ramps) { [ramp([1], [2], tempo(80)), ramp([2], [3], tempo(120))] }

      it "starts the second from the first's target" do
        expect(clock(position(3)) - clock(position(2))).to be_within(1).of(2_432_790_649)
      end
    end

    context "with a chorale's fermata, at 100 in 3/4" do
      let(:conductor) do
        described_class.new(starting_tempo: tempo(100), starting_meter: "3/4", fermatas: [fermata([2, 2], [2, 3])])
      end

      it "lengthens the held count" do
        expect(clock(position(2, 3))).to eq 3_600_000_000
      end

      it "leaves the counts after it at their tempo" do
        expect(clock(position(3))).to eq 4_200_000_000
      end

      it "maps a clock time inside the fermata back into its span" do
        expect(musical(3_000_000_000)).to eq [2, 2, 480, 0]
      end

      it "holds the tempo rather than changing it" do
        expect(conductor.tempo_at(position(2, 2, 480))).to eq tempo(100)
      end
    end

    context "with a fermata inside a ramp" do
      let(:tempo_ramps) { [ramp([1], [2], tempo(80))] }
      let(:fermatas) { [fermata([1, 2], [1, 3])] }

      it "stretches the ramp's clock time under the fermata" do
        expect(clock(position(2))).to eq seconds(6 * Math.log(1.5) + 6 * Math.log(1.1))
      end

      it "maps the end back" do
        expect(musical(clock(position(2)))).to eq [2, 1, 0, 0]
      end

      it "maps a time inside the fermata back into its span" do
        expect(musical(clock(position(1, 2, 480)))).to eq [1, 2, 480, 0]
      end
    end

    context "with a fermata on the final count" do
      let(:fermatas) { [fermata([4, 4], [5], 3)] }

      it "lengthens the total by its stretch" do
        expect(clock(position(5))).to eq 9_000_000_000
      end
    end

    it "accepts a flow's positions" do
      flow = HeadMusic::Content::Flow.new
      expect(conductor.musical_to_clock(flow.position("2:1")).nanoseconds).to eq 2_000_000_000
    end
  end
end
