require "spec_helper"

describe HeadMusic::Notation::MEI::AccidentalReading do
  def spelling(letter, octave = 4, sounding: nil, written: nil)
    HeadMusic::Notation::MEI::PitchReading::Spelling.new(letter, octave, sounding, written)
  end

  it "takes the key's alteration where none is written" do
    expect(described_class.new(-2).alteration(spelling("E"))).to eq(-1)
  end

  it "doubles letters past seven fifths" do
    expect(described_class.new(8).alteration(spelling("F"))).to eq 2
  end

  it "keeps a written accidental for later notes at its letter and octave only" do
    reading = described_class.new(0)
    reading.alteration(spelling("F", written: 1))
    expect([reading.alteration(spelling("F")), reading.alteration(spelling("F", 5))]).to eq [1, 0]
  end

  it "sounds a gestural accidental without carrying it" do
    reading = described_class.new(0)
    expect([reading.alteration(spelling("B", sounding: -1)), reading.alteration(spelling("B"))]).to eq [-1, 0]
  end

  it "carries what is shown, while sounding what is gestural" do
    reading = described_class.new(0)
    expect([reading.alteration(spelling("C", sounding: 1, written: 0)), reading.alteration(spelling("C"))]).to eq [1, 0]
  end
end
