require "spec_helper"

describe HeadMusic::Notation::ABC::PitchWriter do
  def pitch(name)
    HeadMusic::Rudiment::Pitch.get(name)
  end

  subject(:writer) { described_class.new(key_signature) }

  let(:key_signature) { HeadMusic::Rudiment::KeySignature.get("C major") }

  describe "#token" do
    context "with octave marks" do
      it "writes the middle-C octave as an uppercase letter" do
        expect(writer.token(pitch("C4"))).to eq "C"
      end

      it "writes the octave above middle C as a lowercase letter" do
        expect(writer.token(pitch("C5"))).to eq "c"
      end

      it "adds one comma per octave below the uppercase base" do
        expect(writer.token(pitch("C3"))).to eq "C,"
      end

      it "adds two commas two octaves below the uppercase base" do
        expect(writer.token(pitch("C2"))).to eq "C,,"
      end

      it "adds one apostrophe per octave above the lowercase base" do
        expect(writer.token(pitch("C6"))).to eq "c'"
      end

      it "adds two apostrophes two octaves above the lowercase base" do
        expect(writer.token(pitch("C7"))).to eq "c''"
      end
    end

    context "with explicit accidentals in C major" do
      it "marks a sharp with a caret" do
        expect(writer.token(pitch("F#4"))).to eq "^F"
      end

      it "marks a flat with an underscore" do
        expect(writer.token(pitch("Bb4"))).to eq "_B"
      end

      it "marks a double sharp with two carets" do
        expect(writer.token(pitch("Fx4"))).to eq "^^F"
      end

      it "marks a double flat with two underscores" do
        expect(writer.token(pitch("Bbb3"))).to eq "__B,"
      end
    end

    context "when the key signature implies the alteration" do
      let(:key_signature) { HeadMusic::Rudiment::KeySignature.get("G major") }

      it "omits the mark for a sharp in the key" do
        expect(writer.token(pitch("F#4"))).to eq "F"
      end

      it "marks a natural against the key with an equals sign" do
        expect(writer.token(pitch("F4"))).to eq "=F"
      end
    end

    context "when a prior accidental persists within the bar" do
      it "omits the mark on a repeated altered note" do
        writer.token(pitch("F#4"))
        expect(writer.token(pitch("F#4"))).to eq "F"
      end

      it "cancels a prior sharp with an equals sign" do
        writer.token(pitch("F#4"))
        expect(writer.token(pitch("F4"))).to eq "=F"
      end

      it "does not apply the accidental to the same letter in a different octave" do
        writer.token(pitch("F#4"))
        expect(writer.token(pitch("F#5"))).to eq "^f"
      end
    end
  end

  describe "#start_new_bar" do
    it "requires the mark again after the bar line" do
      writer.token(pitch("F#4"))
      writer.start_new_bar
      expect(writer.token(pitch("F#4"))).to eq "^F"
    end

    it "does not require cancellation after the bar line" do
      writer.token(pitch("F#4"))
      writer.start_new_bar
      expect(writer.token(pitch("F4"))).to eq "F"
    end

    context "when the key signature alters the letter" do
      let(:key_signature) { HeadMusic::Rudiment::KeySignature.get("G major") }

      it "reverts to the key signature after an explicit natural" do
        writer.token(pitch("F4"))
        writer.start_new_bar
        expect(writer.token(pitch("F#4"))).to eq "F"
      end
    end
  end

  describe "round-trip through PitchBuilder" do
    def reparse(tokens, key_signature)
      builder = HeadMusic::Notation::ABC::PitchBuilder.new(key_signature)
      tokens.map do |token|
        builder.pitch(token[/[A-Ga-g]/], token[/[',]+\z/], token[/\A[\^_=]+/])
      end
    end

    let(:key_signature) { HeadMusic::Rudiment::KeySignature.get("G major") }

    it "reproduces the original pitches when tokens are re-parsed in sequence" do
      pitches = %w[F#4 F4 F#4 G4 Bb3 B3 F#5 C6].map { |name| pitch(name) }
      tokens = pitches.map { |original| writer.token(original) }
      expect(reparse(tokens, key_signature)).to eq pitches
    end
  end
end
