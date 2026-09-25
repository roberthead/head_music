require "spec_helper"

describe HeadMusic::Notation::Kern::KeyReader do
  describe ".fifths" do
    {"*k[]" => 0, "*k[f#]" => 1, "*k[f#c#g#d#a#e#b#]" => 7, "*k[b-]" => -1, "*k[b-e-a-d-]" => -4}.each do |field, fifths|
      it "reads #{field} as #{fifths}" do
        expect(described_class.fifths(field)).to eq fifths
      end
    end

    it "raises an unsupported-feature error for a non-standard signature" do
      expect { described_class.fifths("*k[f#b-]", line_number: 6) }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Non-standard key signature.*\(line 6\)/)
    end

    it "raises an unsupported-feature error for sharps out of order" do
      expect { described_class.fifths("*k[c#f#]") }.to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError)
    end
  end

  describe ".tonal_context" do
    {
      "*G:" => "G major", "*a:" => "A minor", "*B-:" => "B♭ major", "*f#:" => "F♯ minor",
      "*d:dor" => "D dorian", "*G:mix" => "G mixolydian", "*e:phr" => "E phrygian"
    }.each do |field, name|
      it "reads #{field} as #{name}" do
        expect(described_class.tonal_context(field).name).to eq name
      end
    end

    it "reads a mode as a Mode" do
      expect(described_class.tonal_context("*d:dor")).to be_a HeadMusic::Rudiment::Mode
    end

    it "raises an unsupported-feature error for an unrecognized mode" do
      expect { described_class.tonal_context("*d:xyz", line_number: 3) }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Unrecognized mode "xyz".*\(line 3\)/)
    end
  end

  describe "recognition" do
    it "recognizes a signature" do
      expect(%w[*k[] *k[f#] *G: *M3/4].map { |field| described_class.signature?(field) }).to eq [true, true, false, false]
    end

    it "recognizes a designation" do
      expect(%w[*G: *e-: *d:dor *k[] *?: *clefG2].map { |field| described_class.designation?(field) })
        .to eq [true, true, true, false, false, false]
    end
  end

  describe "writing" do
    {3 => "*k[f#c#g#]", 0 => "*k[]", -2 => "*k[b-e-]"}.each do |fifths, field|
      it "writes #{fifths} fifths as #{field}" do
        expect(described_class.signature_field(fifths)).to eq field
      end
    end

    %w[*G: *a: *B-: *f#: *d:dor *g:mix].each do |field|
      it "writes #{field} back" do
        expect(described_class.designation_field(described_class.tonal_context(field))).to eq field
      end
    end

    it "writes nothing for a scale type kern cannot designate" do
      expect(described_class.designation_field(HeadMusic::Rudiment::KeySignature.get("A harmonic_minor"))).to be_nil
    end
  end
end
