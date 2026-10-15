require "spec_helper"

describe HeadMusic::Notation::MusicXML::XmlReading do
  let(:parse_error) { HeadMusic::Notation::MusicXML::ParseError }

  describe ".rational" do
    it "reads a decimal exactly" do
      expect(described_class.rational("0.125", "<duration>")).to eq Rational(1, 8)
    end

    it "refuses an exponent too large for Rational, naming the measure" do
      expect { described_class.rational("1e999999999", "<duration>", measure: "3") }
        .to raise_error(parse_error, /Unreadable <duration> "1e999999999" \(measure 3\)/)
    end

    it "refuses any exponent, which no decimal has" do
      expect { described_class.rational("1E2", "<duration>") }.to raise_error(parse_error)
    end

    it "refuses a number of absurd length" do
      expect { described_class.rational("1" * 1000, "<duration>") }.to raise_error(parse_error, /Unreadable <duration>/)
    end
  end
end
