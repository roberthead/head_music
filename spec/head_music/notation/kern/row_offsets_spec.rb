require "spec_helper"

describe HeadMusic::Notation::Kern::RowOffsets do
  it "puts a row at each attack alone where no dynamic falls between them" do
    expect(described_class.for([0, Rational(1, 2)], [Rational(1, 2)], 1)).to eq [0, Rational(1, 2)]
  end

  it "spaces the fewest null rows evenly to land on a dynamic between attacks" do
    expect(described_class.for([0], [Rational(3, 4)], 1)).to eq [0, Rational(1, 4), Rational(1, 2), Rational(3, 4)]
  end

  it "lands on every dynamic between the same two attacks" do
    expect(described_class.for([0], [Rational(1, 3), Rational(1, 2)], 1))
      .to eq [0, Rational(1, 6), Rational(1, 3), Rational(1, 2), Rational(2, 3), Rational(5, 6)]
  end
end
