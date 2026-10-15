require "spec_helper"

describe HeadMusic::Notation::MEI::Decimals do
  it "writes an integer without a point" do
    expect(described_class.format(Rational(3))).to eq "3"
  end

  it "writes a decimal that ends exactly" do
    expect([Rational(5, 2), Rational(33, 32), Rational(1, 5)].map { |value| described_class.format(value) })
      .to eq %w[2.5 1.03125 0.2]
  end

  it "rounds a repeating decimal to four places" do
    expect([Rational(4, 3), Rational(2, 3)].map { |value| described_class.format(value) }).to eq %w[1.3333 0.6667]
  end

  it "writes a negative decimal" do
    expect(described_class.format(Rational(-1, 4))).to eq "-0.25"
  end
end
