require "spec_helper"

describe HeadMusic::Rudiment::RhythmicValue::NameReader do
  def read(name)
    described_class.read(name)&.to_s
  end

  it "reads a plain value" do
    expect(read("quarter")).to eq "quarter"
  end

  it "reads a dotted value" do
    expect(read("double-dotted half")).to eq "double-dotted half"
  end

  it "reads a chain of tied values" do
    expect(read("half tied to eighth tied to sixteenth")).to eq "half tied to eighth tied to sixteenth"
  end

  it "reads a leading ratio word" do
    expect(read("5:4 sixteenth")).to eq "5:4 sixteenth"
  end

  it "reads a ratio word on each tied link" do
    expect(read("triplet eighth tied to quarter")).to eq "triplet eighth tied to quarter"
  end

  it "reads the underscored word form" do
    expect(read("dotted_quarter")).to eq "dotted quarter"
  end

  it "does not read a tuplet word it cannot place as a plain value" do
    expect(read("eighth triplet")).to be_nil
  end

  it "does not read a ratio that names no tuplet" do
    expect(read("1:1 eighth")).to be_nil
  end

  describe ".dots_from_words" do
    specify { expect(described_class.dots_from_words("triple_dotted_quarter")).to eq 3 }
    specify { expect(described_class.dots_from_words("quarter")).to eq 0 }
  end
end
