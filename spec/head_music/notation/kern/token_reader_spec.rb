require "spec_helper"

describe HeadMusic::Notation::Kern::TokenReader do
  def read(field)
    described_class.read(field, line_number: 9)
  end

  def summary(field)
    token = read(field)
    [token.type, token.pitches.map(&:to_s), token.rhythmic_value.to_s, token.tie]
  end

  it "reads a null token" do
    expect(read(".").type).to eq :null
  end

  it "reads a note" do
    expect(summary("4cc#")).to eq [:note, ["C♯5"], "quarter", nil]
  end

  it "reads a rest" do
    expect(summary("2r")).to eq [:rest, [], "half", nil]
  end

  it "reads a double r as a rest" do
    expect(summary("1rr")).to eq [:rest, [], "whole", nil]
  end

  it "reads a chord" do
    expect(summary("4C 4E 4G")).to eq [:note, %w[C3 E3 G3], "quarter", nil]
  end

  it "reads the fraction of a whole note it spans" do
    expect(read("8.GG").fraction).to eq Rational(3, 16)
  end

  {"[4g" => :start, "4g_" => :middle, "4g]" => :end, "[4c [4e" => :start}.each do |field, tie|
    it "reads the tie in #{field}" do
      expect(read(field).tie).to eq tie
    end
  end

  it "counts notes and rests as attacks" do
    expect(%w[4c 4r . 8qc].map { |field| read(field).attack? }).to eq [true, true, false, false]
  end

  describe "ignored signifiers" do
    %w[8cL 8cJ 2d; 4c/ 4c\\ 4c' 4c~ 4c^ (4c 4c) {4c 4c} 4c#X 4cy 4cT 4cXX 4ek].each do |field|
      it "drops the signifiers in #{field}" do
        expect(read(field).type).to eq :note
      end
    end

    it "drops a grace note" do
      expect(read("8qc").type).to eq :grace
    end

    it "drops a grace note from a chord" do
      expect(summary("4c 8qe")).to eq [:note, ["C4"], "quarter", nil]
    end
  end

  describe "errors" do
    it "raises an unsupported-feature error naming an unrecognized signifier" do
      expect { read("4c@") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Unsupported signifier "@" in token "4c@" \(line 9\)/)
    end

    it "raises an unsupported-feature error for a tuplet duration" do
      expect { read("6c") }.to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Tuplet.*6c/)
    end

    it "raises an unsupported-feature error for chord notes with different durations" do
      expect { read("4c 8e") }.to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /different durations/)
    end

    it "raises an unsupported-feature error for a chord tied only in part" do
      expect { read("[4c 4e") }.to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /tied only in part/)
    end

    it "raises an unsupported-feature error for a chord holding a rest" do
      expect { read("4c 4r") }.to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /cannot hold a rest/)
    end

    it "raises for mixed pitch letters" do
      expect { read("4cd") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /Unrecognized pitch in "4cd"/)
    end

    it "raises for a token with no duration" do
      expect { read("c") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /has no duration/)
    end

    it "raises for a token with no pitch or rest" do
      expect { read("4") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /no pitch or rest/)
    end

    it "raises for a tied rest" do
      expect { read("[4r") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /rest cannot be tied/)
    end

    it "raises for conflicting tie marks" do
      expect { read("[4c]") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /Conflicting tie marks/)
    end
  end
end
