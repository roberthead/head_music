require "spec_helper"

describe HeadMusic::Notation::BeamGroups do
  def meter(signature)
    HeadMusic::Rudiment::Meter.get(signature)
  end

  def event(levels, onset, beam_break_before = nil)
    described_class::Event.new(levels: levels, onset: onset, beam_break_before: beam_break_before)
  end

  def eighths(count, from: 0)
    Array.new(count) { |index| event(1, from + Rational(index, 8)) }
  end

  describe ".group_start?" do
    it "starts a group on each quarter in 4/4" do
      expect([0, Rational(1, 8), Rational(1, 4), Rational(3, 4)].map { |onset| described_class.group_start?(onset, meter("4/4")) })
        .to eq [true, false, true, true]
    end

    it "starts a group on each dotted quarter in 6/8" do
      expect([Rational(1, 4), Rational(3, 8)].map { |onset| described_class.group_start?(onset, meter("6/8")) }).to eq [false, true]
    end

    it "starts a group only at the downbeat in 3/8" do
      expect([0, Rational(1, 8), Rational(1, 4)].map { |onset| described_class.group_start?(onset, meter("3/8")) }).to eq [true, false, false]
    end

    it "starts a group everywhere when the beat is longer than any note value" do
      expect(described_class.group_start?(Rational(1, 8), meter("12/1"))).to be true
    end
  end

  describe ".groups" do
    it "groups eighths by the quarter in 4/4" do
      expect(described_class.groups(eighths(8), meter("4/4"))).to eq [[0, 1], [2, 3], [4, 5], [6, 7]]
    end

    it "groups eighths by the dotted quarter in 6/8" do
      expect(described_class.groups(eighths(6), meter("6/8"))).to eq [[0, 1, 2], [3, 4, 5]]
    end

    it "keeps a whole bar of 3/8 in one group" do
      expect(described_class.groups(eighths(3), meter("3/8"))).to eq [[0, 1, 2]]
    end

    it "sets an unbeamable event apart, with its neighbors on each side" do
      events = [event(1, 0), event(0, Rational(1, 16)), event(2, Rational(3, 16)), event(2, Rational(7, 32))]
      expect(described_class.groups(events, meter("2/4"))).to eq [[0], [1], [2, 3]]
    end

    it "breaks where the author breaks and joins where the author joins" do
      events = [event(1, 0), event(1, Rational(1, 8), true), event(1, Rational(1, 4), false), event(1, Rational(3, 8))]
      expect(described_class.groups(events, meter("2/4"))).to eq [[0], [1, 2, 3]]
    end

    it "answers no groups for no events" do
      expect(described_class.groups([], meter("4/4"))).to eq []
    end
  end
end
