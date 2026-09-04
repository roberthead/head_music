require "spec_helper"

describe HeadMusic::Notation::LilyPond::MeterReader do
  def meter(source)
    described_class.meter(HeadMusic::Notation::LilyPond::Lexer.new(source).tokens.first)
  end

  describe ".meter" do
    %w[4/4 3/4 6/8 2/2 5/4 7/8 12/16 1/1 3/256].each do |signature|
      it "reads #{signature}" do
        expect(meter(signature).to_s).to eq signature
      end
    end

    %w[4/3 0/4 4/0 4 4/512 3/6].each do |signature|
      it "raises for #{signature}" do
        expect { meter(signature) }
          .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Invalid \\time signature "#{Regexp.escape(signature)}"/)
      end
    end

    it "raises for a non-number token" do
      expect { meter("common") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Invalid \\time signature/)
    end

    it "raises for a missing token" do
      expect { described_class.meter(nil) }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Invalid \\time signature/)
    end

    it "reports the line number" do
      expect { meter("\n4/3") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /line 2/)
    end
  end
end
