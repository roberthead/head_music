require "spec_helper"

describe HeadMusic::Rudiment::DurationComparison do
  def unit(name) = HeadMusic::Rudiment::RhythmicUnit.get(name)

  def value(name) = HeadMusic::Rudiment::RhythmicValue.get(name)

  def duration(name) = HeadMusic::Rudiment::RhythmicDuration.get(name)

  describe "#same_duration_as?" do
    it "matches a dotted value with the tied values it lasts as long as" do
      expect(value("dotted half")).to be_same_duration_as(duration("half tied to quarter"))
    end

    it "matches a unit with the values it splits into" do
      expect(unit(:eighth)).to be_same_duration_as(duration("sixteenth tied to sixteenth"))
    end

    it "matches a unit with a value of that unit" do
      expect(unit(:whole)).to be_same_duration_as(value(:whole))
    end

    it "matches tuplet values by the time they fill" do
      expect(value("triplet quarter")).to be_same_duration_as(duration("triplet eighth tied to triplet eighth"))
    end

    it "tells a plain value from a tuplet of the same unit" do
      expect(value(:quarter)).not_to be_same_duration_as(value("triplet quarter"))
    end

    it "reads a name" do
      expect(duration("half tied to quarter")).to be_same_duration_as("dotted half")
    end

    it "does not match a name it cannot read" do
      expect(value(:quarter)).not_to be_same_duration_as("garbage")
    end

    it "does not match something that is not a duration" do
      expect(value(:quarter)).not_to be_same_duration_as(Rational(1, 4))
    end
  end

  describe "#<=>" do
    it "orders a value and a duration by length" do
      expect(value(:quarter)).to be < duration("quarter tied to eighth")
    end

    it "orders a unit and a value by length" do
      expect(unit(:half)).to be > value("dotted quarter")
    end

    it "sorts the three kinds together" do
      sorted = [duration("half tied to quarter"), unit(:eighth), value(:half)].sort
      expect(sorted.map(&:to_s)).to eq ["eighth", "half", "half tied to quarter"]
    end

    it "answers zero for the same length written two ways, though they are not ==" do
      dotted, tied = value("dotted half"), duration("half tied to quarter")
      expect([dotted <=> tied, dotted == tied]).to eq [0, false]
    end

    it "answers nil for something that is not a duration" do
      expect(value(:quarter) <=> 0.25).to be_nil
    end
  end
end
