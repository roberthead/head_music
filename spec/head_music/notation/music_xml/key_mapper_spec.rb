require "spec_helper"

describe HeadMusic::Notation::MusicXML::KeyMapper do
  describe ".fifths" do
    {
      "C major" => 0,
      "G major" => 1,
      "F major" => -1,
      "Eb major" => -3,
      "A minor" => 0,
      "D dorian" => 0,
      "F# minor" => 3,
      "G# major" => 8
    }.each do |key_signature_name, expected_fifths|
      it "maps #{key_signature_name.inspect} to #{expected_fifths}" do
        key_signature = HeadMusic::Rudiment::KeySignature.get(key_signature_name)
        expect(described_class.fifths(key_signature)).to eq expected_fifths
      end
    end

    it "normalizes a key signature name string through KeySignature.get" do
      expect(described_class.fifths("G major")).to eq 1
    end
  end

  describe ".mode" do
    {
      "C major" => "major",
      "A minor" => "minor",
      "D dorian" => "dorian",
      "C ionian" => "major",
      "A aeolian" => "minor",
      "E phrygian" => "phrygian",
      "F lydian" => "lydian",
      "G mixolydian" => "mixolydian",
      "B locrian" => "locrian"
    }.each do |key_signature_name, expected_mode|
      it "maps #{key_signature_name.inspect} to #{expected_mode.inspect}" do
        key_signature = HeadMusic::Rudiment::KeySignature.get(key_signature_name)
        expect(described_class.mode(key_signature)).to eq expected_mode
      end
    end

    it "normalizes a key signature name string through KeySignature.get" do
      expect(described_class.mode("A minor")).to eq "minor"
    end

    it "raises a RenderError for a scale type without a MusicXML mode" do
      key_signature = HeadMusic::Rudiment::KeySignature.get("C harmonic_minor")
      expect { described_class.mode(key_signature) }
        .to raise_error(HeadMusic::Notation::MusicXML::RenderError, /scale type/i)
    end
  end

  describe ".tonal_context" do
    {
      [0, "major"] => "C major",
      [0, "minor"] => "A minor",
      [-3, "minor"] => "C minor",
      [0, "dorian"] => "D dorian",
      [1, "mixolydian"] => "D mixolydian",
      [-1, "lydian"] => "B♭ lydian",
      [7, "major"] => "C♯ major",
      [7, "minor"] => "A♯ minor",
      [-7, "minor"] => "A♭ minor"
    }.each do |(fifths, mode), name|
      it "reads #{fifths} fifths in #{mode} as #{name}" do
        expect(described_class.tonal_context(fifths, mode).name).to eq name
      end
    end

    it "answers nil for a mode it has no tonal context for" do
      expect(described_class.tonal_context(0, "none")).to be_nil
    end

    it "reads back every mode the writer writes as that mode" do
      modes = described_class::MODE_NAMES_BY_SCALE_TYPE.values.uniq
      expect(modes.map { |mode| described_class.mode(described_class.tonal_context(2, mode)) }).to eq modes
    end

    it "reads back the signature's fifths for every mode" do
      fifths = described_class::SCALE_TYPES_BY_MODE_NAME.keys.map do |mode|
        described_class.fifths(HeadMusic::Rudiment::KeySignature.get(described_class.tonal_context(-2, mode).name))
      end
      expect(fifths.uniq).to eq [-2]
    end
  end
end
