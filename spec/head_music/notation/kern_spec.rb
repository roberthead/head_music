require "spec_helper"

describe HeadMusic::Notation::Kern do
  describe ".parse" do
    it "raises for nil input" do
      expect { described_class.parse(nil) }.to raise_error(described_class::ParseError, /blank/)
    end

    it "raises for whitespace-only input" do
      expect { described_class.parse(" \n\t\n") }.to raise_error(described_class::ParseError, /blank/)
    end
  end

  describe described_class::ParseError do
    it "names the line it was raised for" do
      error = described_class.new("Bad token", line_number: 7, snippet: "4x")
      expect([error.message, error.line_number, error.snippet]).to eq ["Bad token (line 7)", 7, "4x"]
    end

    it "is a notation parse error" do
      expect(described_class.new("Bad")).to be_a HeadMusic::Notation::ParseError
    end
  end

  describe described_class::UnsupportedFeatureError do
    it "is a kern parse error" do
      expect(described_class.new("Tuplet")).to be_a HeadMusic::Notation::Kern::ParseError
    end
  end
end
