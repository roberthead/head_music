require "spec_helper"

describe HeadMusic::Rudiment::RhythmicValue::Parser do
  describe ".parse" do
    context "with shorthand notation" do
      it "parses 'q' as quarter" do
        rv = described_class.parse("q")
        expect(rv).to be_a(HeadMusic::Rudiment::RhythmicValue)
        expect(rv.to_s).to eq "quarter"
      end

      it "parses 'h' as half" do
        rv = described_class.parse("h")
        expect(rv.to_s).to eq "half"
      end

      it "parses 'e' as eighth" do
        rv = described_class.parse("e")
        expect(rv.to_s).to eq "eighth"
      end

      it "parses 's' as sixteenth" do
        rv = described_class.parse("s")
        expect(rv.to_s).to eq "sixteenth"
      end

      it "parses 'w' as whole" do
        rv = described_class.parse("w")
        expect(rv.to_s).to eq "whole"
      end
    end

    context "with dotted shorthand notation" do
      it "parses 'q.' as dotted quarter" do
        rv = described_class.parse("q.")
        expect(rv.to_s).to eq "dotted quarter"
      end

      it "parses 'h.' as dotted half" do
        rv = described_class.parse("h.")
        expect(rv.to_s).to eq "dotted half"
      end

      it "parses 'q..' as double-dotted quarter" do
        rv = described_class.parse("q..")
        expect(rv.to_s).to eq "double-dotted quarter"
      end

      it "parses 'q...' as triple-dotted quarter" do
        rv = described_class.parse("q...")
        expect(rv.to_s).to eq "triple-dotted quarter"
      end
    end

    context "with American note names" do
      it "parses 'quarter'" do
        rv = described_class.parse("quarter")
        expect(rv.to_s).to eq "quarter"
      end

      it "parses 'half'" do
        rv = described_class.parse("half")
        expect(rv.to_s).to eq "half"
      end

      it "parses 'eighth'" do
        rv = described_class.parse("eighth")
        expect(rv.to_s).to eq "eighth"
      end

      it "parses 'whole'" do
        rv = described_class.parse("whole")
        expect(rv.to_s).to eq "whole"
      end
    end

    context "with word-based dotted notation" do
      it "parses 'dotted quarter'" do
        rv = described_class.parse("dotted quarter")
        expect(rv.to_s).to eq "dotted quarter"
      end

      it "parses 'double dotted half'" do
        rv = described_class.parse("double dotted half")
        expect(rv.to_s).to eq "double-dotted half"
      end

      it "parses 'triple dotted quarter'" do
        rv = described_class.parse("triple dotted quarter")
        expect(rv.to_s).to eq "triple-dotted quarter"
      end
    end

    context "with British note names" do
      it "parses 'crotchet' as quarter" do
        rv = described_class.parse("crotchet")
        expect(rv.to_s).to eq "quarter"
      end

      it "parses 'minim' as half" do
        rv = described_class.parse("minim")
        expect(rv.to_s).to eq "half"
      end

      it "parses 'quaver' as eighth" do
        rv = described_class.parse("quaver")
        expect(rv.to_s).to eq "eighth"
      end

      it "parses 'semiquaver' as sixteenth" do
        rv = described_class.parse("semiquaver")
        expect(rv.to_s).to eq "sixteenth"
      end
    end

    context "with fraction notation" do
      it "parses '1/4' as quarter" do
        rv = described_class.parse("1/4")
        expect(rv.to_s).to eq "quarter"
      end

      it "parses '1/2' as half" do
        rv = described_class.parse("1/2")
        expect(rv.to_s).to eq "half"
      end

      it "parses '1/8' as eighth" do
        rv = described_class.parse("1/8")
        expect(rv.to_s).to eq "eighth"
      end

      it "parses '1/16' as sixteenth" do
        rv = described_class.parse("1/16")
        expect(rv.to_s).to eq "sixteenth"
      end
    end

    context "with decimal notation" do
      it "parses '0.25' as quarter" do
        rv = described_class.parse("0.25")
        expect(rv.to_s).to eq "quarter"
      end

      it "parses '0.5' as half" do
        rv = described_class.parse("0.5")
        expect(rv.to_s).to eq "half"
      end

      it "parses '1.0' as whole" do
        rv = described_class.parse("1.0")
        expect(rv.to_s).to eq "whole"
      end
    end

    context "with whitespace" do
      it "handles leading whitespace" do
        rv = described_class.parse("  q")
        expect(rv.to_s).to eq "quarter"
      end

      it "handles trailing whitespace" do
        rv = described_class.parse("q  ")
        expect(rv.to_s).to eq "quarter"
      end

      it "handles both" do
        rv = described_class.parse("  dotted quarter  ")
        expect(rv.to_s).to eq "dotted quarter"
      end
    end

    context "with invalid input" do
      it "returns nil for nil" do
        expect(described_class.parse(nil)).to be_nil
      end

      it "returns nil for empty string" do
        expect(described_class.parse("")).to be_nil
      end

      it "returns nil for invalid name" do
        expect(described_class.parse("invalid")).to be_nil
      end
    end
  end

  describe "#initialize" do
    subject(:parser) { described_class.new(input) }

    context "with 'q.'" do
      let(:input) { "q." }

      it "exposes identifier" do
        expect(parser.identifier).to eq "q."
      end

      it "exposes rhythmic_value" do
        expect(parser.rhythmic_value).to be_a(HeadMusic::Rudiment::RhythmicValue)
        expect(parser.rhythmic_value.to_s).to eq "dotted quarter"
      end
    end

    context "with invalid input" do
      let(:input) { "invalid" }

      it "returns nil for rhythmic_value" do
        expect(parser.rhythmic_value).to be_nil
      end
    end
  end
end
