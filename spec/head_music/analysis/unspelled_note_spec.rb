require "spec_helper"

describe HeadMusic::Analysis::UnspelledNote do
  subject(:note) { described_class.new(number: 61, onset: 1, duration: 0.25) }

  it "holds Rational onsets and durations" do
    expect([note.onset, note.duration]).to eq [Rational(1), Rational(1, 4)]
    expect(note.onset).to be_a Rational
  end

  it "has no voice by default" do
    expect(note.voice).to be_nil
  end

  it "is built positionally too" do
    expect(described_class.new(61, 1, Rational(1, 4), :alto).voice).to eq :alto
  end

  it "is equal to a note given the same values in another numeric type" do
    expect(note).to eql described_class.new(number: 61, onset: Rational(1), duration: Rational(1, 4))
  end

  it "refuses a key number that is not an integer" do
    expect { described_class.new(number: "C#4", onset: 0, duration: 1) }.to raise_error(ArgumentError)
  end
end
