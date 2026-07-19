require "spec_helper"

describe HeadMusic::Rudiment::UnpitchedSound do
  subject(:sound) { described_class.get("snare_drum") }

  it_behaves_like "a sound"

  describe ".get" do
    context "when given an instrument name" do
      specify { expect(described_class.get("snare_drum").name_key).to eq :snare_drum }
      specify { expect(described_class.get("snare drum").name_key).to eq :snare_drum }
      specify { expect(described_class.get("Snare Drum").name_key).to eq :snare_drum }
      specify { expect(described_class.get(:snare_drum).name_key).to eq :snare_drum }
    end

    context "when given an alias name" do
      it "resolves to the canonical instrument" do
        expect(described_class.get("tabor").name_key).to eq :snare_drum
      end
    end

    context "when given an Instrument instance" do
      let(:instrument) { HeadMusic::Instruments::Instrument.get("snare_drum") }

      it "wraps the instrument" do
        expect(described_class.get(instrument).instrument).to be instrument
      end
    end

    context "when given a pitched instrument" do
      subject(:sound) { described_class.get("violin") }

      it "wraps the instrument, since any instrument body can make an unpitched sound" do
        expect(sound.name_key).to eq :violin
      end

      it "remains unpitched" do
        expect(sound.pitched?).to be false
      end
    end

    context "when given no argument or nil" do
      it "returns the generic instrument-less singleton" do
        expect(described_class.get).to be described_class.get(nil)
      end

      it "returns a frozen singleton" do
        expect(described_class.get).to be_frozen
      end

      it "has no instrument" do
        expect(described_class.get.instrument).to be_nil
      end

      it "has no name_key" do
        expect(described_class.get.name_key).to be_nil
      end

      it "is named 'unpitched'" do
        expect(described_class.get.to_s).to eq "unpitched"
      end

      it "does not equal an instrument-backed sound" do
        expect(described_class.get).not_to eq described_class.get("snare drum")
      end
    end

    context "when given an unknown name" do
      it "returns nil" do
        expect(described_class.get("flurble")).to be_nil
      end
    end

    context "when given an UnpitchedSound instance" do
      it "returns the same object" do
        expect(described_class.get(sound)).to be sound
      end
    end
  end

  describe "value equality" do
    it "collapses aliases to the canonical instrument" do
      expect(described_class.get("tabor")).to eq described_class.get("snare drum")
    end

    it "treats alias-resolved sounds as duplicates" do
      sounds = [described_class.get("tabor"), described_class.get("snare drum")]
      expect(sounds.uniq.length).to eq 1
    end

    it "distinguishes sounds on different instruments" do
      expect(described_class.get("snare drum")).not_to eq described_class.get("bass drum")
    end
  end

  describe "#pitched?" do
    it "is false" do
      expect(sound.pitched?).to be false
    end
  end

  describe "#name" do
    it "is the instrument's name" do
      expect(sound.name).to eq "snare drum"
    end
  end

  describe "localization" do
    it "is available through the wrapped instrument" do
      expect(sound.instrument.translation(:de)).to eq "Leinentrommel"
    end
  end

  describe "interaction with Pitch" do
    let(:pitch) { HeadMusic::Rudiment::Pitch.get("C4") }

    it "does not equal a pitch" do
      expect(sound == pitch).to be false
    end

    it "is not equaled by a pitch" do
      expect(pitch == sound).to be false
    end
  end
end
