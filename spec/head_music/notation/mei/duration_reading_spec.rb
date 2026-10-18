require "spec_helper"

describe HeadMusic::Notation::MEI::DurationReading do
  def element(xml)
    REXML::Document.new(xml).root
  end

  def reading(default = nil)
    described_class.new(HeadMusic::Notation::MEI::Editorial.new(HeadMusic::Notation::MEI::IdIndex.new, budget: 10), default)
  end

  describe "#rhythmic_value" do
    it "reads an element's @dur and @dots" do
      expect(reading.rhythmic_value(element(%(<note dur="4" dots="1"/>))).name).to eq "dotted quarter"
    end

    it "reads a chord's duration from the notes that all state it" do
      chord = element(%(<chord><note dur="2"/><note dur="2"/></chord>))
      expect(reading.rhythmic_value(chord).name).to eq "half"
    end

    it "falls back to the default when a chord's notes disagree" do
      chord = element(%(<chord><note dur="2"/><note dur="4"/></chord>))
      expect(reading("eighth").rhythmic_value(chord).name).to eq "eighth"
    end

    it "makes a grace note with no duration an eighth" do
      expect(reading.rhythmic_value(element("<note/>"), grace: true).name).to eq "eighth"
    end

    it "scales by a tuplet ratio" do
      expect(reading.rhythmic_value(element(%(<note dur="8"/>)), ratio: HeadMusic::Rudiment::TupletRatio.get([3, 2])).fraction).to eq Rational(1, 12)
    end

    it "raises with no duration and no default" do
      expect { reading.rhythmic_value(element("<note/>")) }.to raise_error(HeadMusic::Notation::MEI::ParseError, /no @dur/)
    end
  end

  describe "#open?" do
    it "is true of a space with no length and no default" do
      expect(reading.open?(element("<space/>"))).to be true
    end

    it "is false where a default is in force" do
      expect(reading("quarter").open?(element("<space/>"))).to be false
    end
  end
end
