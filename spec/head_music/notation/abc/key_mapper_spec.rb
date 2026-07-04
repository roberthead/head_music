require "spec_helper"

describe HeadMusic::Notation::ABC::KeyMapper do
  describe "#key_signature_name" do
    {
      "C" => "C major",
      "G" => "G major",
      "Bb" => "Bb major",
      "F#" => "F# major",
      "Gmaj" => "G major",
      "Gmajor" => "G major",
      "Gion" => "G major",
      "Gionian" => "G major",
      "Gm" => "G minor",
      "Gmin" => "G minor",
      "Gminor" => "G minor",
      "Gaeo" => "G minor",
      "Gaeolian" => "G minor",
      "F#m" => "F# minor",
      "Ador" => "A dorian",
      "Adorian" => "A dorian",
      "Ephr" => "E phrygian",
      "Ephrygian" => "E phrygian",
      "Flyd" => "F lydian",
      "Flydian" => "F lydian",
      "DMix" => "D mixolydian",
      "Dmixolydian" => "D mixolydian",
      "Bloc" => "B locrian",
      "Blocrian" => "B locrian"
    }.each do |abc_value, expected_name|
      it "maps #{abc_value.inspect} to #{expected_name.inspect}" do
        expect(described_class.new(abc_value).key_signature_name).to eq expected_name
      end
    end

    it "matches mode words case-insensitively" do
      expect(described_class.new("ADoRiAn").key_signature_name).to eq "A dorian"
    end

    it "accepts an uppercase mode abbreviation" do
      expect(described_class.new("GMIN").key_signature_name).to eq "G minor"
    end

    it "accepts a lone uppercase M as minor" do
      expect(described_class.new("GM").key_signature_name).to eq "G minor"
    end

    it "allows whitespace between the tonic and the mode word" do
      expect(described_class.new("F# min").key_signature_name).to eq "F# minor"
    end

    it "strips surrounding whitespace" do
      expect(described_class.new("  Ador  ").key_signature_name).to eq "A dorian"
    end

    it "accepts a unicode flat sign" do
      expect(described_class.new("B♭").key_signature_name).to eq "B♭ major"
    end

    it "raises a ParseError for an unrecognized mode word" do
      expect { described_class.new("Gfoo").key_signature_name }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /mode/i)
    end

    it "raises a ParseError for a mode abbreviation shorter than three letters" do
      expect { described_class.new("Gma").key_signature_name }
        .to raise_error(HeadMusic::Notation::ABC::ParseError)
    end

    it "raises a ParseError for 'none'" do
      expect { described_class.new("none").key_signature_name }
        .to raise_error(HeadMusic::Notation::ABC::ParseError)
    end

    it "raises a ParseError for 'HP'" do
      expect { described_class.new("HP").key_signature_name }
        .to raise_error(HeadMusic::Notation::ABC::ParseError)
    end

    it "raises a ParseError for 'Hp'" do
      expect { described_class.new("Hp").key_signature_name }
        .to raise_error(HeadMusic::Notation::ABC::ParseError)
    end

    it "includes the line number in the error when given one" do
      expect { described_class.new("none", line_number: 7).key_signature_name }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /line 7/)
    end
  end

  describe "#key_signature" do
    it "returns a KeySignature" do
      key_signature = described_class.new("Ador").key_signature
      expect(key_signature).to be_a(HeadMusic::Rudiment::KeySignature)
      expect(key_signature.name).to eq "A dorian"
    end
  end
end
