require "spec_helper"

describe HeadMusic::Content::SoundResolver do
  describe ".resolve" do
    it "returns a frozen empty array for nil" do
      result = described_class.resolve(nil)
      expect(result).to eq([]).and be_frozen
    end

    it "resolves a pitch name to a pitch" do
      expect(described_class.resolve("C4").map(&:to_s)).to eq ["C4"]
    end

    it "resolves an array of pitch names, de-duplicating" do
      expect(described_class.resolve(["C4", "E4", "C4"]).map(&:to_s)).to eq ["C4", "E4"]
    end

    it "resolves a bare unpitched instrument name to an unpitched sound" do
      expect(described_class.resolve("snare drum").map(&:name_key)).to eq [:snare_drum]
    end

    it "passes an existing unpitched sound through unchanged" do
      sound = HeadMusic::Rudiment::UnpitchedSound.get("snare drum")
      expect(described_class.resolve(sound)).to eq [sound]
    end

    it "raises for an unparseable name" do
      expect { described_class.resolve("bogus") }
        .to raise_error(ArgumentError, 'unknown sound: "bogus"')
    end

    it "raises with guidance for a pitched instrument name" do
      expect { described_class.resolve("violin") }
        .to raise_error(ArgumentError, /"violin" is a pitched instrument/)
    end
  end
end
