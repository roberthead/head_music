require "spec_helper"

describe HeadMusic::Rudiment::Pitch::Parser do
  describe ".parse" do
    context "with valid pitch strings" do
      it "parses 'C4'" do
        pitch = described_class.parse("C4")
        expect(pitch).to be_a(HeadMusic::Rudiment::Pitch)
        expect(pitch.to_s).to eq "C4"
      end

      it "parses 'F#4'" do
        pitch = described_class.parse("F#4")
        expect(pitch).to be_a(HeadMusic::Rudiment::Pitch)
        expect(pitch.to_s).to eq "F♯4"
      end

      it "parses 'Bb3'" do
        pitch = described_class.parse("Bb3")
        expect(pitch).to be_a(HeadMusic::Rudiment::Pitch)
        expect(pitch.to_s).to eq "B♭3"
      end

      it "parses 'A0'" do
        pitch = described_class.parse("A0")
        expect(pitch.to_s).to eq "A0"
      end

      it "parses 'C8'" do
        pitch = described_class.parse("C8")
        expect(pitch.to_s).to eq "C8"
      end
    end

    context "with whitespace" do
      it "handles leading whitespace" do
        pitch = described_class.parse("  C4")
        expect(pitch.to_s).to eq "C4"
      end

      it "handles trailing whitespace" do
        pitch = described_class.parse("C4  ")
        expect(pitch.to_s).to eq "C4"
      end

      it "handles both leading and trailing whitespace" do
        pitch = described_class.parse("  F#4  ")
        expect(pitch.to_s).to eq "F♯4"
      end
    end

    context "with invalid input" do
      it "returns nil for nil" do
        expect(described_class.parse(nil)).to be_nil
      end

      it "returns nil for empty string" do
        expect(described_class.parse("")).to be_nil
      end

      it "returns nil for invalid pitch name" do
        expect(described_class.parse("invalid")).to be_nil
      end

      it "returns nil for just a letter" do
        expect(described_class.parse("C")).to be_nil
      end

      it "returns nil for just a register" do
        expect(described_class.parse("4")).to be_nil
      end

      it "returns nil for invalid letter" do
        expect(described_class.parse("H4")).to be_nil
      end
    end

    context "with additional text" do
      it "extracts pitch from string with other content" do
        pitch = described_class.parse("F#4 dotted-quarter")
        expect(pitch).to be_a(HeadMusic::Rudiment::Pitch)
        expect(pitch.to_s).to eq "F♯4"
      end
    end
  end

  describe "#initialize" do
    subject(:parser) { described_class.new(input_string) }

    context "with 'F#4'" do
      let(:input_string) { "F#4" }

      it "exposes identifier" do
        expect(parser.identifier).to eq "F#4"
      end

      it "exposes letter_name" do
        expect(parser.letter_name).to eq "F"
      end

      it "exposes alteration" do
        expect(parser.alteration.to_s).to eq "♯"
      end

      it "exposes register" do
        expect(parser.register).to eq 4
      end

      it "exposes spelling" do
        expect(parser.spelling.to_s).to eq "F♯"
      end

      it "exposes pitch" do
        expect(parser.pitch.to_s).to eq "F♯4"
      end
    end

    context "with 'C4'" do
      let(:input_string) { "C4" }

      it "exposes letter_name" do
        expect(parser.letter_name).to eq "C"
      end

      it "exposes nil alteration" do
        expect(parser.alteration).to be_nil
      end

      it "exposes register" do
        expect(parser.register).to eq 4
      end
    end

    context "with invalid input" do
      let(:input_string) { "invalid" }

      it "returns nil for letter_name" do
        expect(parser.letter_name).to be_nil
      end

      it "returns nil for alteration" do
        expect(parser.alteration).to be_nil
      end

      it "returns nil for register" do
        expect(parser.register).to be_nil
      end

      it "returns nil for spelling" do
        expect(parser.spelling).to be_nil
      end

      it "returns nil for pitch" do
        expect(parser.pitch).to be_nil
      end
    end
  end
end
