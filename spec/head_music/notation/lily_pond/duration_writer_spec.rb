require "spec_helper"

describe HeadMusic::Notation::LilyPond::DurationWriter do
  describe ".token" do
    {
      "whole" => "1",
      "half" => "2",
      "quarter" => "4",
      "eighth" => "8",
      "sixteenth" => "16",
      "thirty-second" => "32",
      "dotted quarter" => "4.",
      "double dotted half" => "2..",
      "double whole" => "\\breve",
      "longa" => "\\longa",
      "maxima" => "\\maxima"
    }.each do |value, expected|
      it "renders a #{value} as #{expected}" do
        expect(described_class.token(value)).to eq expected
      end
    end

    it "appends dots to the named long durations" do
      value = HeadMusic::Rudiment::RhythmicValue.new(:double_whole, dots: 1)
      expect(described_class.token(value)).to eq "\\breve."
    end

    it "ignores the tied value, which the render plan joins with tie marks" do
      value = HeadMusic::Rudiment::RhythmicValue.get("half tied to eighth")
      expect(described_class.token(value)).to eq "2"
    end

    it "raises a render error for a unit without a LilyPond duration" do
      value = instance_double(HeadMusic::Rudiment::RhythmicValue, unit_name: "whatsit", dots: 0)
      allow(HeadMusic::Rudiment::RhythmicValue).to receive(:get).and_return(value)
      expect { described_class.token(value) }
        .to raise_error(HeadMusic::Notation::LilyPond::RenderError, /no LilyPond duration/)
    end
  end
end
