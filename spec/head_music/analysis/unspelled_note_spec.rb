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

  it "takes key numbers from 0 to 127" do
    expect([0, 127].map { |number| described_class.new(number: number, onset: 0, duration: 1).number }).to eq [0, 127]
  end

  it "refuses a key number outside 0 to 127" do
    [-1, 128].each do |number|
      expect { described_class.new(number: number, onset: 0, duration: 1) }.to raise_error(ArgumentError, /outside 0..127/)
    end
  end

  it "takes a duration of zero, as a grace note has" do
    expect(described_class.new(number: 60, onset: 0, duration: 0).duration).to eq 0
  end

  it "refuses a negative duration" do
    expect { described_class.new(number: 60, onset: 0, duration: Rational(-1, 4)) }.to raise_error(ArgumentError, /negative/)
  end
end
