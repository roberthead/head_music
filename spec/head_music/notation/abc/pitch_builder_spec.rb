require "spec_helper"

describe HeadMusic::Notation::ABC::PitchBuilder do
  def pitch(name)
    HeadMusic::Rudiment::Pitch.get(name)
  end

  subject(:builder) { described_class.new(key_signature) }

  let(:key_signature) { HeadMusic::Rudiment::KeySignature.get("C major") }

  describe "#pitch" do
    context "with octave marks" do
      it "maps an uppercase letter to the middle-C octave" do
        expect(builder.pitch("C", "")).to eq pitch("C4")
      end

      it "maps a lowercase letter to the octave above middle C" do
        expect(builder.pitch("c", "")).to eq pitch("C5")
      end

      it "lowers an uppercase letter by one octave per comma" do
        expect(builder.pitch("C", ",")).to eq pitch("C3")
      end

      it "raises a lowercase letter by one octave per apostrophe" do
        expect(builder.pitch("c", "'")).to eq pitch("C6")
      end

      it "lowers a lowercase letter by one octave per comma" do
        expect(builder.pitch("c", ",,")).to eq pitch("C3")
      end

      it "raises an uppercase letter by one octave per apostrophe" do
        expect(builder.pitch("C", "''")).to eq pitch("C6")
      end
    end

    context "with explicit accidental marks in C major" do
      it "sharpens a note marked with a caret" do
        expect(builder.pitch("F", "", "^")).to eq pitch("F#4")
      end

      it "double-sharpens a note marked with two carets" do
        expect(builder.pitch("F", "", "^^")).to eq pitch("Fx4")
      end

      it "flattens a note marked with an underscore" do
        expect(builder.pitch("B", "", "_")).to eq pitch("Bb4")
      end

      it "double-flattens a note marked with two underscores" do
        expect(builder.pitch("B", "", "__")).to eq pitch("Bbb4")
      end

      it "leaves a note marked with an equals sign natural" do
        expect(builder.pitch("F", "", "=")).to eq pitch("F4")
      end
    end

    context "with unrecognized accidental marks" do
      it "raises a ParseError" do
        expect { builder.pitch("F", "", "^_") }.to raise_error(HeadMusic::Notation::ABC::ParseError)
      end
    end

    context "when the key signature has sharps" do
      let(:key_signature) { HeadMusic::Rudiment::KeySignature.get("G major") }

      it "sharpens an unmarked uppercase altered letter" do
        expect(builder.pitch("F", "")).to eq pitch("F#4")
      end

      it "sharpens an unmarked lowercase altered letter" do
        expect(builder.pitch("f", "")).to eq pitch("F#5")
      end

      it "leaves unaffected letters unaltered" do
        expect(builder.pitch("G", "")).to eq pitch("G4")
      end

      it "restores an unmarked note marked natural to its natural pitch" do
        expect(builder.pitch("F", "", "=")).to eq pitch("F4")
      end
    end

    context "when the key signature has flats" do
      let(:key_signature) { HeadMusic::Rudiment::KeySignature.get("F major") }

      it "flattens an unmarked altered letter" do
        expect(builder.pitch("B", "")).to eq pitch("Bb4")
      end

      it "leaves unaffected letters unaltered" do
        expect(builder.pitch("A", "")).to eq pitch("A4")
      end
    end
  end

  describe "accidental persistence within a bar" do
    context "when in C major" do
      before { builder.pitch("F", "", "^") }

      it "applies a prior accidental to a later unmarked note of the same letter and octave" do
        expect(builder.pitch("F", "")).to eq pitch("F#4")
      end

      it "does not apply a prior accidental to the same letter in a different octave" do
        expect(builder.pitch("f", "")).to eq pitch("F5")
      end
    end

    context "when in G major after a natural sign" do
      let(:key_signature) { HeadMusic::Rudiment::KeySignature.get("G major") }

      before { builder.pitch("F", "", "=") }

      it "keeps a later unmarked note of the same letter and octave natural" do
        expect(builder.pitch("F", "")).to eq pitch("F4")
      end
    end
  end

  describe "#start_new_bar" do
    it "reverts unmarked notes to natural after an explicit sharp in C major" do
      builder.pitch("F", "", "^")
      builder.start_new_bar
      expect(builder.pitch("F", "")).to eq pitch("F4")
    end

    context "when the key signature alters the letter" do
      let(:key_signature) { HeadMusic::Rudiment::KeySignature.get("G major") }

      it "reverts unmarked notes to the key signature after an explicit natural" do
        builder.pitch("F", "", "=")
        builder.start_new_bar
        expect(builder.pitch("F", "")).to eq pitch("F#4")
      end
    end
  end
end
