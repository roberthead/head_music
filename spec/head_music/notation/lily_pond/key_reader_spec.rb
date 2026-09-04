require "spec_helper"

describe HeadMusic::Notation::LilyPond::KeyReader do
  def key(source)
    pitch_token, mode_token = HeadMusic::Notation::LilyPond::Lexer.new(source).tokens
    described_class.key_signature(pitch_token, mode_token)
  end

  describe ".key_signature" do
    {
      "g \\major" => "G major", "a \\minor" => "A minor", "fis \\major" => "F♯ major", "es \\major" => "E♭ major",
      "bes \\minor" => "B♭ minor", "cis \\minor" => "C♯ minor", "d \\dorian" => "D dorian", "e \\phrygian" => "E phrygian",
      "f \\lydian" => "F lydian", "g \\mixolydian" => "G mixolydian", "a \\aeolian" => "A aeolian",
      "b \\locrian" => "B locrian", "c \\ionian" => "C ionian"
    }.each do |source, name|
      it "reads \\key #{source} as #{name}" do
        expect(key(source)).to eq HeadMusic::Rudiment::KeySignature.get(name)
      end
    end

    it "reads every mode the writer emits back to its scale type" do
      HeadMusic::Notation::LilyPond::KeyMapper::MODE_COMMANDS_BY_SCALE_TYPE.each do |scale_type, command|
        expect(key("c #{command}").scale_type.name.to_s).to eq scale_type
      end
    end

    it "raises for an unrecognized mode" do
      expect { key("c \\blues") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unrecognized mode "\\blues" in \\key command/)
    end

    {
      "the mode is missing" => "c",
      "the mode is not a command" => "c major",
      "the pitch is not a note" => "\\major \\major",
      "the pitch has octave marks" => "c' \\major",
      "the pitch has a duration" => "c4 \\major"
    }.each do |problem, source|
      it "raises when #{problem}" do
        expect { key(source) }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /expects a pitch and a mode/)
      end
    end

    it "raises for a double-altered tonic" do
      expect { key("cisis \\major") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /double-altered tonic "cisis"/)
    end

    it "reports the line number" do
      expect { key("\n\nc \\blues") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /line 3/)
    end
  end
end
