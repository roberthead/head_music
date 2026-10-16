require "spec_helper"

describe HeadMusic::MIDI::BarLayout do
  let(:division) { 96 }

  def meter(tick, numerator, denominator)
    HeadMusic::MIDI::TimeSignature.new(tick, numerator, denominator, 24)
  end

  def note(on, off)
    [HeadMusic::MIDI::NoteOn.new(tick: on, channel: 0, key: 60, velocity: 80), HeadMusic::MIDI::NoteOff.new(tick: off, channel: 0, key: 60)]
  end

  def budget(events)
    HeadMusic::MIDI::Budget.new(HeadMusic::MIDI::Reader.new(HeadMusic::MIDI::SMF.file(division: division, tracks: [events])).read)
  end

  def layout(events)
    budget = budget(events)
    described_class.new(budget.time_signatures, division: division, end_tick: budget.end_tick)
  end

  def shape(layout)
    layout.bars.map { |bar| [bar.number, bar.start, bar.length, bar.meter.to_s] }
  end

  describe "with no time signature" do
    subject(:bars) { layout(note(0, 9 * division)) }

    it "lays out 4/4 bars from bar 1" do
      expect(shape(bars)).to eq [[1, 0r, 1r, "4/4"], [2, 1r, 1r, "4/4"], [3, 2r, 1r, "4/4"]]
    end
  end

  describe "a meter change" do
    it "applies at the barline it falls on" do
      bars = layout([meter(0, 4, 4), meter(4 * division, 3, 4), *note(0, 10 * division)])
      expect(shape(bars)).to eq [[1, 0r, 1r, "4/4"], [2, 1r, 3/4r, "3/4"], [3, 7/4r, 3/4r, "3/4"]]
    end

    it "lays out a mid-piece 1/4 bar, as played-out repeats write it" do
      bars = layout([meter(0, 4, 4), meter(4 * division, 1, 4), meter(5 * division, 4, 4), *note(0, 9 * division)])
      expect(shape(bars)).to eq [[1, 0r, 1r, "4/4"], [2, 1r, 1/4r, "1/4"], [3, 5/4r, 1r, "4/4"]]
    end

    it "raises UnsupportedFeatureError naming the bar when it falls within one" do
      events = [meter(0, 4, 4), meter(6 * division, 3, 4), *note(0, 12 * division)]
      expect { layout(events).bars }.to raise_error(HeadMusic::MIDI::UnsupportedFeatureError, "a time signature changes the meter within bar 2")
    end

    it "snaps to the sixty-fourth-note point within a tick of it, counted from the one before" do
      bars = layout([meter(0, 4, 4), meter(4 * division + 1, 3, 4), meter(7 * division - 1, 2, 4), *note(0, 10 * division)])
      expect(shape(bars)).to eq [[1, 0r, 1r, "4/4"], [2, 1r, 3/4r, "3/4"], [3, 7/4r, 1/2r, "2/4"], [4, 9/4r, 1/2r, "2/4"]]
    end

    it "snaps to the triplet sixty-fourth-note point within a tick of it" do
      bars = layout([meter(0, 3, 4), meter(division / 3 + 1, 3, 4), *note(0, 4 * division)])
      expect(shape(bars).first).to eq [0, 0r, 1/12r, "3/4"]
    end

    context "with 480 ticks to the quarter" do
      let(:division) { 480 }

      it "raises UnsupportedFeatureError naming the tick of one between grid points" do
        events = [meter(0, 4, 4), meter(4 * division + 10, 3, 4), *note(0, 10 * division)]
        expect { layout(events).bars }.to raise_error(HeadMusic::MIDI::UnsupportedFeatureError, /\Athe time signature at tick 1930 falls between grid points/)
      end
    end

    it "takes the last of several at one tick" do
      bars = layout([meter(0, 2, 4), meter(0, 3, 4), meter(3 * division, 2, 4), meter(3 * division, 3, 8), *note(0, 6 * division)])
      expect(shape(bars)).to eq [[1, 0r, 3/4r, "3/4"], [2, 3/4r, 3/8r, "3/8"], [3, 9/8r, 3/8r, "3/8"]]
    end

    it "ignores a restatement of the meter in force, within a bar or on one" do
      bars = layout([meter(0, 3, 4), meter(9 * division / 2, 3, 4), meter(6 * division, 3, 4), *note(0, 9 * division)])
      expect(shape(bars)).to eq [[1, 0r, 3/4r, "3/4"], [2, 3/4r, 3/4r, "3/4"], [3, 3/2r, 3/4r, "3/4"]]
    end

    it "ignores one at or after the end" do
      bars = layout([meter(0, 3, 4), *note(0, 6 * division), meter(6 * division, 5, 4)])
      expect(shape(bars)).to eq [[1, 0r, 3/4r, "3/4"], [2, 3/4r, 3/4r, "3/4"]]
    end

    it "starts from 4/4 when the first falls after tick 0" do
      bars = layout([meter(4 * division, 3, 4), *note(0, 7 * division)])
      expect(shape(bars)).to eq [[1, 0r, 1r, "4/4"], [2, 1r, 3/4r, "3/4"]]
    end
  end

  describe "a pickup" do
    it "is bar 0 when a shorter first meter gives way within a bar of the next" do
      bars = layout([meter(0, 1, 4), meter(division, 4, 4), *note(0, 9 * division)])
      expect(shape(bars)).to eq [[0, 0r, 1/4r, "4/4"], [1, 1/4r, 1r, "4/4"], [2, 5/4r, 1r, "4/4"]]
    end

    it "is bar 0 when the meter is restated within the first bar" do
      bars = layout([meter(0, 3, 4), meter(division / 3, 3, 4), *note(0, 4 * division)])
      expect(shape(bars)).to eq [[0, 0r, 1/12r, "3/4"], [1, 1/12r, 3/4r, "3/4"], [2, 5/6r, 3/4r, "3/4"]]
      expect(bars.first_number).to eq 0
    end

    it "is not read from a lone 1/4 meter" do
      bars = layout([meter(0, 1, 4), *note(0, 3 * division)])
      expect(shape(bars)).to eq [[1, 0r, 1/4r, "1/4"], [2, 1/4r, 1/4r, "1/4"], [3, 1/2r, 1/4r, "1/4"]]
    end

    it "is not read from leading silence in a full first bar" do
      bars = layout([meter(0, 4, 4), meter(4 * division, 3, 4), *note(2 * division, 7 * division)])
      expect(shape(bars)).to eq [[1, 0r, 1r, "4/4"], [2, 1r, 3/4r, "3/4"]]
      expect(bars.first_number).to eq 1
    end

    it "is not read from first-meter bars that fill out before the change" do
      bars = layout([meter(0, 1, 4), meter(2 * division, 4, 4), *note(0, 6 * division)])
      expect(shape(bars)).to eq [[1, 0r, 1/4r, "1/4"], [2, 1/4r, 1/4r, "1/4"], [3, 1/2r, 1r, "4/4"]]
    end
  end

  describe "the bar count" do
    {
      "no time signature" => [[], 9],
      "a pickup" => [[[0, 1, 4], [1, 4, 4]], 10],
      "a pickup through restatement" => [[[0, 3, 4], [Rational(1, 3), 3, 4]], 7],
      "a lone 1/4 meter" => [[[0, 1, 4]], 5],
      "a meter change on a barline" => [[[0, 4, 4], [4, 3, 4]], 11],
      "a mid-piece 1/4 bar" => [[[0, 4, 4], [4, 1, 4], [5, 4, 4]], 14],
      "a change at the end" => [[[0, 3, 4], [7, 2, 4]], 7],
      "events only at tick 0" => [[], 0]
    }.each do |name, (meters, quarters)|
      it "agrees with Budget#bar_count for #{name}" do
        events = [*meters.map { |at, numerator, denominator| meter((at * division).to_i, numerator, denominator) }, *note(0, quarters * division)]
        expect(layout(events).bars.length).to eq budget(events).bar_count
      end
    end
  end

  describe ".beat" do
    it "is the meter's beat" do
      expect(%w[4/4 6/8 3/2].map { |meter| described_class.beat(HeadMusic::Rudiment::Meter.get(meter)).to_s }).to eq ["quarter", "dotted quarter", "half"]
    end

    it "is a dotted double whole in a compound meter of whole notes" do
      expect(described_class.beat(HeadMusic::Rudiment::Meter.get("6/1")).fraction).to eq 3
    end
  end

  describe "#bar_at" do
    subject(:bars) { layout([meter(0, 1, 4), meter(division, 4, 4), *note(0, 9 * division)]) }

    it "finds the bar holding a time, a downbeat starting its own bar" do
      expect([0r, 1/8r, 1/4r, 5/4r, 9/4r].map { |time| bars.bar_at(time).number }).to eq [0, 0, 1, 2, 2]
    end

    it "gives the bar starts and the end" do
      expect([bars.bar_starts, bars.end_time]).to eq [{0 => 0r, 1 => 1/4r, 2 => 5/4r}, 9/4r]
    end
  end
end
