require "spec_helper"

describe HeadMusic::Notation::LilyPond::DurationReader do
  subject(:reader) { described_class.new }

  def token(source)
    HeadMusic::Notation::LilyPond::Lexer.new(source).tokens.first
  end

  describe "#rhythmic_value" do
    {
      "c\\maxima" => "maxima", "c\\longa" => "longa", "c\\breve" => "double whole",
      "c1" => "whole", "c2" => "half", "c4" => "quarter", "c8" => "eighth", "c16" => "sixteenth",
      "c32" => "thirty-second", "c64" => "sixty-fourth", "c128" => "hundred twenty-eighth",
      "c256" => "two hundred fifty-sixth"
    }.each do |source, name|
      it "reads #{source} as a #{name}" do
        expect(reader.rhythmic_value(token(source)).to_s).to eq name
      end
    end

    it "reads every duration the writer emits back to its unit" do
      HeadMusic::Notation::LilyPond::DurationWriter::DURATIONS_BY_UNIT_NAME.each do |unit_name, duration|
        expect(reader.rhythmic_value(token("c#{duration}")).unit_name).to eq unit_name
      end
    end

    it "reads dots" do
      expect(reader.rhythmic_value(token("c4.")).to_s).to eq "dotted quarter"
    end

    it "reads a double dot" do
      expect(reader.rhythmic_value(token("c2..")).to_s).to eq "double-dotted half"
    end

    it "reads a triple dot" do
      expect(reader.rhythmic_value(token("c2...")).to_s).to eq "triple-dotted half"
    end

    it "defaults the first note to a quarter" do
      expect(reader.rhythmic_value(token("c")).to_s).to eq "quarter"
    end

    it "carries the last explicit duration forward" do
      reader.rhythmic_value(token("c8"))
      expect(reader.rhythmic_value(token("d")).to_s).to eq "eighth"
    end

    it "carries dots forward" do
      reader.rhythmic_value(token("g4."))
      expect(reader.rhythmic_value(token("a")).to_s).to eq "dotted quarter"
    end

    it "carries across a rest" do
      reader.rhythmic_value(token("r2"))
      expect(reader.rhythmic_value(token("a")).to_s).to eq "half"
    end

    it "does not carry an invalid duration forward" do
      expect { reader.rhythmic_value(token("c3")) }.to raise_error(HeadMusic::Notation::LilyPond::ParseError)
      expect(reader.rhythmic_value(token("d")).to_s).to eq "quarter"
    end

    %w[c3 c0 c512 c5].each do |source|
      it "raises for #{source}" do
        expect { reader.rhythmic_value(token(source)) }
          .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unrecognized duration/)
      end
    end

    it "raises for four dots" do
      expect { reader.rhythmic_value(token("c4....")) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Too many dots/)
    end

    it "reports the line number" do
      expect { reader.rhythmic_value(token("\n\nc3")) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /line 3/)
    end
  end

  describe "#whole_bar_fraction" do
    it "spans one whole note for R1" do
      expect(reader.whole_bar_fraction(token("R1"))).to eq 1
    end

    it "applies the multiplier" do
      expect(reader.whole_bar_fraction(token("R1*3/4"))).to eq Rational(3, 4)
    end

    it "applies an integer multiplier" do
      expect(reader.whole_bar_fraction(token("R1*2"))).to eq 2
    end

    it "spans a dotted duration" do
      expect(reader.whole_bar_fraction(token("R2."))).to eq Rational(3, 4)
    end

    it "carries the duration forward to the next note" do
      reader.whole_bar_fraction(token("R1*4/4"))
      expect(reader.rhythmic_value(token("c")).to_s).to eq "whole"
    end

    it "raises for a zero denominator" do
      expect { reader.whole_bar_fraction(token("R1*4/0")) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Zero denominator/)
    end

    it "raises for a zero numerator" do
      expect { reader.whole_bar_fraction(token("R1*0/4")) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /positive duration/)
    end
  end
end
