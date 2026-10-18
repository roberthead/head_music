require "spec_helper"

describe HeadMusic::MIDI::MeterChanges do
  let(:division) { 96 }

  def meter(tick, numerator, denominator)
    HeadMusic::MIDI::TimeSignature.new(tick, numerator, denominator, 24)
  end

  def changes(*time_signatures, end_tick: 16 * division)
    described_class.new(time_signatures, division: division, end_tick: end_tick)
  end

  def shape(pairs)
    pairs.map { |at, meter| [at, meter.to_s] }
  end

  describe "#to_a" do
    it "opens in 4/4 with no time signature" do
      expect(shape(changes.to_a)).to eq [[0r, "4/4"]]
    end

    it "takes the last of several at one tick" do
      expect(shape(changes(meter(0, 2, 4), meter(0, 3, 4)).to_a)).to eq [[0r, "3/4"]]
    end

    it "snaps to the sixty-fourth-note point within a tick of it" do
      expect(shape(changes(meter(0, 4, 4), meter(4 * division + 1, 3, 4)).to_a)).to eq [[0r, "4/4"], [1r, "3/4"]]
    end

    it "ignores one at or after the end" do
      expect(shape(changes(meter(0, 3, 4), meter(6 * division, 5, 4), end_tick: 6 * division).to_a)).to eq [[0r, "3/4"]]
    end

    it "raises UnsupportedFeatureError for one between grid points" do
      expect { changes(meter(0, 4, 4), meter(4 * division + 2, 3, 4)).to_a }.to raise_error(HeadMusic::MIDI::UnsupportedFeatureError, /tick 386/)
    end
  end

  describe "#pickup?" do
    it "is true when a shorter first meter gives way within a bar of the next" do
      expect(changes(meter(0, 1, 4), meter(division, 4, 4))).to be_pickup
    end

    it "is false when first-meter bars fill out before the change" do
      expect(changes(meter(0, 1, 4), meter(2 * division, 4, 4))).not_to be_pickup
    end

    it "is false with one meter" do
      expect(changes(meter(0, 1, 4))).not_to be_pickup
    end
  end

  describe "#sections" do
    it "starts after a pickup" do
      expect(shape(changes(meter(0, 1, 4), meter(division, 4, 4)).sections)).to eq [[1/4r, "4/4"]]
    end

    it "skips a restatement of the meter in force" do
      sections = changes(meter(0, 3, 4), meter(3 * division, 3, 4), meter(6 * division, 2, 4)).sections
      expect(shape(sections)).to eq [[0r, "3/4"], [3/2r, "2/4"]]
    end
  end

  describe "#barline?" do
    subject(:meters) { changes(meter(0, 1, 4), meter(division, 4, 4), meter(9 * division, 3, 4)) }

    it "is true on each barline, counted from the pickup's end and each later change" do
      expect([1/4r, 5/4r, 9/4r, 3r].map { |time| meters.barline?(time) }).to all be true
    end

    it "is false within a bar and within the pickup" do
      expect([1/8r, 1/2r, 5/2r].map { |time| meters.barline?(time) }).to all be false
    end
  end
end
