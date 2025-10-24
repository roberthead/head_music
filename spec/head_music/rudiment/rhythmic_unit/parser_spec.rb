require "spec_helper"

describe HeadMusic::Rudiment::RhythmicUnit::Parser do
  specify do
    expect(described_class.new("whole").rhythmic_unit).to be_a(HeadMusic::Rudiment::RhythmicUnit)
    expect(described_class.new("half").rhythmic_unit).to be_a(HeadMusic::Rudiment::RhythmicUnit)
  end

  describe ".parse" do
    context "with tempo shorthand notation" do
      it "parses 'w' as whole" do
        expect(described_class.parse("w")).to eq "whole"
      end

      it "parses 'h' as half" do
        expect(described_class.parse("h")).to eq "half"
      end

      it "parses 'q' as quarter" do
        expect(described_class.parse("q")).to eq "quarter"
      end

      it "parses 'e' as eighth" do
        expect(described_class.parse("e")).to eq "eighth"
      end

      it "parses 's' as sixteenth" do
        expect(described_class.parse("s")).to eq "sixteenth"
      end

      it "parses 't' as thirty-second" do
        expect(described_class.parse("t")).to eq "thirty-second"
      end

      it "parses 'x' as sixty-fourth" do
        expect(described_class.parse("x")).to eq "sixty-fourth"
      end

      it "parses 'o' as hundred twenty-eighth" do
        expect(described_class.parse("o")).to eq "hundred twenty-eighth"
      end

      it "handles uppercase shorthand" do
        expect(described_class.parse("Q")).to eq "quarter"
        expect(described_class.parse("H")).to eq "half"
        expect(described_class.parse("E")).to eq "eighth"
      end

      it "handles shorthand with optional dot" do
        expect(described_class.parse("q.")).to eq "quarter"
        expect(described_class.parse("h.")).to eq "half"
        expect(described_class.parse("e.")).to eq "eighth"
      end
    end

    context "with standard rhythmic unit names" do
      it "parses 'whole'" do
        expect(described_class.parse("whole")).to eq "whole"
      end

      it "parses 'half'" do
        expect(described_class.parse("half")).to eq "half"
      end

      it "parses 'quarter'" do
        expect(described_class.parse("quarter")).to eq "quarter"
      end

      it "parses 'eighth'" do
        expect(described_class.parse("eighth")).to eq "eighth"
      end

      it "parses 'sixteenth'" do
        expect(described_class.parse("sixteenth")).to eq "sixteenth"
      end

      it "parses 'thirty-second'" do
        expect(described_class.parse("thirty-second")).to eq "thirty-second"
      end

      it "parses 'double whole'" do
        expect(described_class.parse("double whole")).to eq "double whole"
      end

      it "parses 'longa'" do
        expect(described_class.parse("longa")).to eq "longa"
      end

      it "parses 'maxima'" do
        expect(described_class.parse("maxima")).to eq "maxima"
      end
    end

    context "with British names" do
      it "parses 'semibreve'" do
        expect(described_class.parse("semibreve")).to eq "semibreve"
      end

      it "parses 'minim'" do
        expect(described_class.parse("minim")).to eq "minim"
      end

      it "parses 'crotchet'" do
        expect(described_class.parse("crotchet")).to eq "crotchet"
      end

      it "parses 'quaver'" do
        expect(described_class.parse("quaver")).to eq "quaver"
      end

      it "parses 'semiquaver'" do
        expect(described_class.parse("semiquaver")).to eq "semiquaver"
      end

      it "parses 'demisemiquaver'" do
        expect(described_class.parse("demisemiquaver")).to eq "demisemiquaver"
      end
    end

    context "with various formats" do
      it "handles names with underscores" do
        expect(described_class.parse("thirty_second")).to eq "thirty-second"
      end

      it "handles mixed case" do
        expect(described_class.parse("WHOLE")).to eq "whole"
        expect(described_class.parse("HaLf")).to eq "half"
        expect(described_class.parse("QuArTeR")).to eq "quarter"
      end

      it "handles extra whitespace" do
        expect(described_class.parse("  whole  ")).to eq "whole"
        expect(described_class.parse("\thalf\n")).to eq "half"
      end
    end

    context "with fraction notation" do
      it "parses '1/4' as quarter" do
        expect(described_class.parse("1/4")).to eq "quarter"
      end

      it "parses '1/2' as half" do
        expect(described_class.parse("1/2")).to eq "half"
      end

      it "parses '1/8' as eighth" do
        expect(described_class.parse("1/8")).to eq "eighth"
      end

      it "parses '1/16' as sixteenth" do
        expect(described_class.parse("1/16")).to eq "sixteenth"
      end

      it "parses '1/32' as thirty-second" do
        expect(described_class.parse("1/32")).to eq "thirty-second"
      end

      it "parses '1/1' as whole" do
        expect(described_class.parse("1/1")).to eq "whole"
      end

      it "parses '2/1' as double whole" do
        expect(described_class.parse("2/1")).to eq "double whole"
      end
    end

    context "with decimal duration notation" do
      it "parses '0.25' as quarter" do
        expect(described_class.parse("0.25")).to eq "quarter"
      end

      it "parses '0.5' as half" do
        expect(described_class.parse("0.5")).to eq "half"
      end

      it "parses '0.125' as eighth" do
        expect(described_class.parse("0.125")).to eq "eighth"
      end

      it "parses '1.0' as whole" do
        expect(described_class.parse("1.0")).to eq "whole"
      end
    end

    context "with invalid input" do
      it "returns nil for nil input" do
        expect(described_class.parse(nil)).to be_nil
      end

      it "returns nil for empty string" do
        expect(described_class.parse("")).to be_nil
        expect(described_class.parse("   ")).to be_nil
      end

      it "returns nil for invalid names" do
        expect(described_class.parse("invalid")).to be_nil
        expect(described_class.parse("xyz")).to be_nil
        expect(described_class.parse("123")).to be_nil
      end

      it "returns nil for invalid shorthand" do
        expect(described_class.parse("z")).to be_nil
        expect(described_class.parse("qq")).to be_nil
        expect(described_class.parse("h.h")).to be_nil
      end
    end

    context "when integrating with HeadMusic::Rudiment::RhythmicUnit" do
      it "parses all valid tempo shorthand into valid rhythmic units" do
        %w[w h q e s t x o].each do |shorthand|
          parsed = described_class.parse(shorthand)
          expect(parsed).not_to be_nil
          expect(HeadMusic::Rudiment::RhythmicUnit.get(parsed)).not_to be_nil
        end
      end

      it "allows RhythmicUnit.get to accept tempo shorthand" do
        expect(HeadMusic::Rudiment::RhythmicUnit.get("q")).to eq HeadMusic::Rudiment::RhythmicUnit.get("quarter")
        expect(HeadMusic::Rudiment::RhythmicUnit.get("h")).to eq HeadMusic::Rudiment::RhythmicUnit.get("half")
        expect(HeadMusic::Rudiment::RhythmicUnit.get("w")).to eq HeadMusic::Rudiment::RhythmicUnit.get("whole")
        expect(HeadMusic::Rudiment::RhythmicUnit.get("e")).to eq HeadMusic::Rudiment::RhythmicUnit.get("eighth")
      end
    end
  end

  describe "#american_name" do
    it "returns American name for British input" do
      parser = described_class.new("crotchet")
      expect(parser.american_name).to eq "quarter"
    end

    it "returns American name for American input" do
      parser = described_class.new("quarter")
      expect(parser.american_name).to eq "quarter"
    end

    it "returns American name for shorthand input" do
      parser = described_class.new("q")
      expect(parser.american_name).to eq "quarter"
    end

    it "returns American name for fraction input" do
      parser = described_class.new("1/4")
      expect(parser.american_name).to eq "quarter"
    end

    it "returns American name for decimal input" do
      parser = described_class.new("0.25")
      expect(parser.american_name).to eq "quarter"
    end

    it "returns nil for invalid input" do
      parser = described_class.new("invalid")
      expect(parser.american_name).to be_nil
    end
  end
end
