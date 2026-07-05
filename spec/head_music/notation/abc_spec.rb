require "spec_helper"

describe HeadMusic::Notation::ABC do
  describe "error hierarchy" do
    it "makes ParseError a HeadMusic::Notation::ParseError" do
      expect(described_class::ParseError.ancestors).to include(HeadMusic::Notation::ParseError)
    end

    it "makes HeadMusic::Notation::ParseError a StandardError" do
      expect(HeadMusic::Notation::ParseError.ancestors).to include(StandardError)
    end

    it "makes UnsupportedFeatureError an ABC::ParseError" do
      expect(described_class::UnsupportedFeatureError.ancestors).to include(described_class::ParseError)
    end
  end

  describe described_class::ParseError do
    context "when constructed with line_number and snippet" do
      subject(:error) { described_class.new("unexpected token", line_number: 3, snippet: "X:1") }

      it "exposes the line number" do
        expect(error.line_number).to eq 3
      end

      it "exposes the snippet" do
        expect(error.snippet).to eq "X:1"
      end

      it "appends the line number to the message" do
        expect(error.message).to eq "unexpected token (line 3)"
      end
    end

    context "when constructed without context" do
      subject(:error) { described_class.new("unexpected token") }

      it "has a nil line number" do
        expect(error.line_number).to be_nil
      end

      it "has a nil snippet" do
        expect(error.snippet).to be_nil
      end

      it "leaves the message unmodified" do
        expect(error.message).to eq "unexpected token"
      end
    end
  end

  describe ".parse" do
    context "with Speed the Plough" do
      subject(:composition) { described_class.parse(<<~ABC) }
        X:1
        T:Speed the Plough
        M:4/4
        L:1/8
        K:G
        |:GABc dedB|dedB dedB|c2ec B2dB|c2A2 A2BA|
        GABc dedB|dedB dedB|c2ec B2dB|A2F2 G4:|
      ABC

      let(:voice) { composition.voices.first }
      let(:placements) { voice.placements }

      it "returns a composition" do
        expect(composition).to be_a(HeadMusic::Content::Composition)
      end

      it "names the composition from the title field" do
        expect(composition.name).to eq "Speed the Plough"
      end

      it "sets the meter to 4/4" do
        expect(composition.meter.to_s).to eq "4/4"
      end

      it "sets the key signature to G major" do
        expect(composition.key_signature).to eq HeadMusic::Rudiment::KeySignature.get("G major")
      end

      it "gives the key signature one sharp" do
        expect(composition.key_signature.num_sharps).to eq 1
      end

      it "creates a single voice" do
        expect(composition.voices.length).to eq 1
      end

      it "opens with G4 A4 B4 C5" do
        expect(voice.pitches.first(4).map(&:to_s)).to eq %w[G4 A4 B4 C5]
      end

      it "renders unmarked notes as eighths under L:1/8" do
        expect(placements.first(4).map { |placement| placement.rhythmic_value.name }).to all(eq "eighth")
      end

      it "renders c2 as a quarter note" do
        # placements[16] is the c2 opening the third bar
        expect(placements[16].rhythmic_value.name).to eq "quarter"
      end

      it "pitches c2 as C5" do
        expect(placements[16].pitch.to_s).to eq "C5"
      end

      it "renders the final G4 as a half note" do
        expect(placements.last.rhythmic_value.name).to eq "half"
      end

      it "sharpens the unmarked F under the key signature" do
        # placements[50] is the F2 in the final bar (A2F2 G4)
        expect(placements[50].pitch.to_s).to eq "F♯4"
      end

      it "rolls the ninth note over into the second bar" do
        expect(placements[8].position.to_s).to eq "2:1:000"
      end

      it "places all fifty-two notes" do
        expect(placements.length).to eq 52
      end

      it "starts the repeat on the first bar" do
        expect(composition.bars(1).last.starts_repeat?).to be true
      end

      it "ends the repeat on the final bar" do
        expect(composition.bars(8).last.ends_repeat?).to be true
      end

      it "plays the repeated section twice" do
        expect(composition.bars(8).last.ends_repeat_after_num_plays).to eq 2
      end
    end

    context "with a jig in compound meter" do
      subject(:composition) { described_class.parse(<<~ABC) }
        X:2
        T:Test Jig
        M:6/8
        L:1/8
        K:D
        DED FEF|d2f ecA|
      ABC

      let(:placements) { composition.voices.first.placements }

      it "sets the meter to 6/8" do
        expect(composition.meter.to_s).to eq "6/8"
      end

      it "fills the first bar with six eighth notes" do
        expect(placements.first(6).map { |placement| placement.rhythmic_value.name }).to all(eq "eighth")
      end

      it "places the sixth eighth on the sixth beat" do
        expect(placements[5].position.to_s).to eq "1:6:000"
      end

      it "rolls the seventh note over into the second bar" do
        expect(placements[6].position.to_s).to eq "2:1:000"
      end

      it "renders d2 as a quarter note" do
        expect(placements[6].rhythmic_value.name).to eq "quarter"
      end

      it "sharpens the unmarked F under the key signature" do
        expect(placements[3].pitch.to_s).to eq "F♯4"
      end

      it "sharpens the unmarked c under the key signature" do
        expect(placements[9].pitch.to_s).to eq "C♯5"
      end
    end

    context "without an L: field" do
      it "defaults the unit note length to a sixteenth when the meter is smaller than 3/4" do
        composition = described_class.parse("X:1\nM:2/4\nK:C\nC|\n")
        placement = composition.voices.first.placements.first
        expect(placement.rhythmic_value.name).to eq "sixteenth"
      end

      it "defaults the unit note length to an eighth when the meter is 3/4 or larger" do
        composition = described_class.parse("X:1\nM:4/4\nK:C\nC|\n")
        placement = composition.voices.first.placements.first
        expect(placement.rhythmic_value.name).to eq "eighth"
      end
    end
  end

  describe ".parse_book" do
    let(:book) do
      <<~ABC
        X:1
        T:Speed the Plough
        M:4/4
        L:1/8
        K:G
        |:GABc dedB|dedB dedB|

        X:2
        T:Test Jig
        M:6/8
        L:1/8
        K:D
        DED FEF|d2f ecA|
      ABC
    end

    it "returns a composition per tune" do
      expect(described_class.parse_book(book).map(&:name)).to eq ["Speed the Plough", "Test Jig"]
    end

    it "parses a single tune into a one-element array" do
      expect(described_class.parse_book("X:1\nK:C\nCDEF|\n").length).to eq 1
    end
  end
end
