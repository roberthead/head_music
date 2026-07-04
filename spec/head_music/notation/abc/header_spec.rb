require "spec_helper"

describe HeadMusic::Notation::ABC::Header do
  describe "field mapping" do
    subject(:header) { described_class.new(abc) }

    let(:abc) do
      <<~ABC
        X:1
        T:The Foggy Dew
        C:Traditional
        O:Ireland
        N:Collected in Sligo
        N:Also known as another tune
        M:3/4
        L:1/8
        V:1
        V:2
        K:G
        GABc dedB|
      ABC
    end

    it "maps X: to the reference number" do
      expect(header.reference_number).to eq "1"
    end

    it "maps T: to the title" do
      expect(header.title).to eq "The Foggy Dew"
    end

    it "maps C: to the composer" do
      expect(header.composer).to eq "Traditional"
    end

    it "maps O: to the origin" do
      expect(header.origin).to eq "Ireland"
    end

    it "collects N: lines in order as annotations" do
      expect(header.annotations).to eq ["Collected in Sligo", "Also known as another tune"]
    end

    it "maps M: to a meter" do
      expect(header.meter).to eq HeadMusic::Rudiment::Meter.get("3/4")
    end

    it "maps L: to a rational unit note length" do
      expect(header.unit_note_length).to eq Rational(1, 8)
    end

    it "collects V: voice ids in order" do
      expect(header.voice_ids).to eq %w[1 2]
    end

    it "maps K: to a key signature" do
      expect(header.key_signature).to be_a(HeadMusic::Rudiment::KeySignature)
      expect(header.key_signature.name).to eq "G major"
    end
  end

  describe "#meter" do
    it "maps M:C to common time" do
      header = described_class.new("M:C\nK:C\n")
      expect(header.meter).to eq HeadMusic::Rudiment::Meter.common_time
    end

    it "maps M:C| to cut time" do
      header = described_class.new("M:C|\nK:C\n")
      expect(header.meter).to eq HeadMusic::Rudiment::Meter.cut_time
    end

    it "defaults to common time when M: is absent" do
      header = described_class.new("K:C\n")
      expect(header.meter).to eq HeadMusic::Rudiment::Meter.common_time
    end

    it "raises a ParseError with the line number for an invalid meter" do
      expect { described_class.new("X:1\nM:jazz\nK:C\n") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /meter.*line 2/i)
    end
  end

  describe "#unit_note_length" do
    it "uses an explicit L: value" do
      header = described_class.new("M:4/4\nL:1/4\nK:C\n")
      expect(header.unit_note_length).to eq Rational(1, 4)
    end

    it "defaults to a sixteenth when the meter fraction is less than three quarters" do
      header = described_class.new("M:2/4\nK:C\n")
      expect(header.unit_note_length).to eq Rational(1, 16)
    end

    it "defaults to an eighth when the meter fraction is three quarters" do
      header = described_class.new("M:3/4\nK:C\n")
      expect(header.unit_note_length).to eq Rational(1, 8)
    end

    it "defaults to an eighth when the meter fraction is three quarters or more" do
      header = described_class.new("M:4/4\nK:C\n")
      expect(header.unit_note_length).to eq Rational(1, 8)
    end

    it "defaults to an eighth when M: is absent" do
      header = described_class.new("K:C\n")
      expect(header.unit_note_length).to eq Rational(1, 8)
    end

    it "raises a ParseError for an invalid unit note length" do
      expect { described_class.new("L:eighth\nK:C\n") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /unit note length/i)
    end
  end

  describe "the required K: field" do
    context "when K: is missing" do
      let(:abc) do
        <<~ABC
          X:1
          T:No Key Here
          M:4/4
        ABC
      end

      it "raises a ParseError" do
        expect { described_class.new(abc) }
          .to raise_error(HeadMusic::Notation::ABC::ParseError, /K:/)
      end
    end

    context "when a field-like line appears after K:" do
      subject(:header) { described_class.new(abc) }

      let(:abc) do
        <<~ABC
          X:1
          K:C
          T:Not A Title Anymore
        ABC
      end

      it "does not treat the line as a header field" do
        expect(header.title).to be_nil
      end

      it "treats the line as body text" do
        expect(header.body).to eq "T:Not A Title Anymore\n"
      end
    end
  end

  describe "unsupported header fields" do
    let(:abc) do
      <<~ABC
        X:1
        Q:120
        K:C
      ABC
    end

    it "raises an UnsupportedFeatureError naming the field and line number" do
      expect { described_class.new(abc) }
        .to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /"Q".*line 2/)
    end
  end

  describe "#body and #body_start_line" do
    subject(:header) { described_class.new(abc) }

    context "when tune lines follow the K: line" do
      let(:abc) do
        <<~ABC
          X:1
          K:D
          DEFG ABde|
          f2ed B2AF|
        ABC
      end

      it "returns the raw text after the K: line" do
        expect(header.body).to eq "DEFG ABde|\nf2ed B2AF|\n"
      end

      it "starts the body on the line after the K: line" do
        expect(header.body_start_line).to eq 3
      end
    end

    context "when nothing follows the K: line" do
      let(:abc) { "X:1\nK:D\n" }

      it "returns an empty body" do
        expect(header.body).to eq ""
      end

      it "still reports the line after the K: line" do
        expect(header.body_start_line).to eq 3
      end
    end

    context "with blank and comment lines before and among the header fields" do
      let(:abc) do
        <<~ABC

          % a comment before the header
          X:1
          % a comment among the fields
          K:D
          DEFG|
        ABC
      end

      it "skips the blank and comment lines when reading fields" do
        expect(header.reference_number).to eq "1"
      end

      it "returns only the tune lines as the body" do
        expect(header.body).to eq "DEFG|\n"
      end

      it "counts the skipped lines toward the body start line" do
        expect(header.body_start_line).to eq 6
      end
    end
  end

  describe "malformed header lines" do
    it "raises a ParseError for a non-field line before K:" do
      expect { described_class.new("X:1\nnot a field\nK:C\n") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /line 2/)
    end
  end
end
