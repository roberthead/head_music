require "spec_helper"

describe HeadMusic::Content::Composition::SchemaValues do
  subject(:values) { described_class.new }

  describe "#position" do
    it "returns nil for a nil value" do
      expect(values.position(nil, "path")).to be_nil
    end

    it "passes a well-formed position string through" do
      expect(values.position("2:3:480", "path")).to eq "2:3:480"
    end

    it "raises with path context on a malformed position" do
      expect { values.position("bogus", "comments[0]") }
        .to raise_error(ArgumentError, /comments\[0\]: unknown position "bogus"/)
    end
  end

  describe "#key_signature" do
    it "returns nil for a nil value" do
      expect(values.key_signature(nil, "path")).to be_nil
    end

    it "resolves a real key signature" do
      expect(values.key_signature("G major", "path").tonic_spelling.to_s).to eq "G"
    end

    it "raises with path context on a hollow key signature" do
      expect { values.key_signature("Q major", "key_signature") }
        .to raise_error(ArgumentError, /key_signature: unknown key signature "Q major"/)
    end
  end

  describe "#meter" do
    it "returns nil for a nil value" do
      expect(values.meter(nil, "path")).to be_nil
    end

    it "raises with path context on an unparseable meter" do
      expect { values.meter("not a meter", "bars[0]") }
        .to raise_error(ArgumentError, /bars\[0\]: unknown meter "not a meter"/)
    end
  end

  describe "#rhythmic_value" do
    it "resolves a real rhythmic value" do
      expect(values.rhythmic_value("quarter", "path")).to be_a(HeadMusic::Rudiment::RhythmicValue)
    end

    it "raises with path context on an unknown rhythmic value" do
      expect { values.rhythmic_value("sesquialtera", "voices[0].placements[0]") }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]: unknown rhythmic value "sesquialtera"/)
    end
  end

  describe "#placement_sounds" do
    it "maps a pitched sound array to pitches" do
      sounds = values.placement_sounds({"sounds" => ["C4"]}, "path")
      expect(sounds.map(&:to_s)).to eq ["C4"]
    end

    it "returns an empty array for a rest" do
      expect(values.placement_sounds({"sounds" => []}, "path")).to eq []
    end

    it "raises when sounds is not an Array" do
      expect { values.placement_sounds({"sounds" => nil}, "voices[0].placements[0]") }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]: sounds must be an Array, got nil/)
    end

    it "raises with element path context on an unknown pitch" do
      expect { values.placement_sounds({"sounds" => ["C4", "H#4"]}, "voices[0].placements[0]") }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]\.sounds\[1\]: unknown pitch "H#4"/)
    end

    it "resolves a generic unpitched sound" do
      sounds = values.placement_sounds({"sounds" => [{"unpitched" => nil}]}, "path")
      expect(sounds.first).to be_a(HeadMusic::Rudiment::UnpitchedSound)
    end

    it "raises on an unpitched hash with extra keys" do
      expect { values.placement_sounds({"sounds" => [{"unpitched" => nil, "y" => 1}]}, "voices[0].placements[0]") }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]\.sounds\[0\]: unknown sound .*"y"/)
    end
  end

  describe "#bar_number" do
    it "returns a valid non-negative bar number" do
      expect(values.bar_number({"number" => 3}, 0)).to eq 3
    end

    it "raises with path context on a negative bar number" do
      expect { values.bar_number({"number" => -1}, 0) }
        .to raise_error(ArgumentError, /bars\[0\]: bar number must be an Integer of at least 0, got -1/)
    end
  end
end
