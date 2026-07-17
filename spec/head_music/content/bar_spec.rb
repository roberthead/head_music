require "spec_helper"

describe HeadMusic::Content::Bar do
  subject(:bar) { described_class.new(composition) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D major", meter: "6/8") }

  its(:key_signature) { is_expected.to be_nil }
  its(:meter) { is_expected.to be_nil }

  context "when specifying the key signature" do
    subject(:bar) { described_class.new(composition, key_signature: "Bb minor") }

    its(:key_signature) { is_expected.to eq "Bb minor" }
  end

  context "when specifying the meter" do
    subject(:bar) { described_class.new(composition, meter: "5/4") }

    its(:meter) { is_expected.to eq "5/4" }
    its(:to_s) { is_expected.to eq "Bar 5/4" }
  end

  describe "#key_signature=" do
    it "coerces a string to a key signature" do
      bar.key_signature = "F# minor"
      expect(bar.key_signature).to be_a(HeadMusic::Rudiment::KeySignature)
    end

    it "coerces to the named key signature" do
      bar.key_signature = "F# minor"
      expect(bar.key_signature).to eq "F# minor"
    end

    it "accepts nil to clear the key signature" do
      bar.key_signature = "F# minor"
      bar.key_signature = nil
      expect(bar.key_signature).to be_nil
    end

    it "passes a key signature object through unchanged" do
      key_signature = HeadMusic::Rudiment::KeySignature.get("Bb major")
      bar.key_signature = key_signature
      expect(bar.key_signature).to be(key_signature)
    end
  end

  describe "#meter=" do
    it "coerces a string to a meter" do
      bar.meter = "6/8"
      expect(bar.meter).to be_a(HeadMusic::Rudiment::Meter)
    end

    it "coerces to the named meter" do
      bar.meter = "6/8"
      expect(bar.meter).to eq "6/8"
    end

    it "accepts nil to clear the meter" do
      bar.meter = "6/8"
      bar.meter = nil
      expect(bar.meter).to be_nil
    end

    it "passes a meter object through unchanged" do
      meter = HeadMusic::Rudiment::Meter.get("3/4")
      bar.meter = meter
      expect(bar.meter).to be(meter)
    end
  end

  describe "repeat structure" do
    it "does not start a repeat by default" do
      expect(bar).not_to be_starts_repeat
    end

    it "does not end a repeat by default" do
      expect(bar).not_to be_ends_repeat
    end

    its(:ends_repeat_after_num_plays) { is_expected.to be_nil }
    its(:plays_on_passes) { is_expected.to be_nil }

    it "plays on every pass by default" do
      expect(bar.plays_on_pass?(17)).to be true
    end

    describe "#starts_repeat=" do
      it "marks the bar as starting a repeat" do
        bar.starts_repeat = true
        expect(bar).to be_starts_repeat
      end
    end

    describe "#ends_repeat_after_num_plays=" do
      it "accepts an integer of two or more" do
        bar.ends_repeat_after_num_plays = 2
        expect(bar).to be_ends_repeat
      end

      it "accepts nil to clear the repeat" do
        bar.ends_repeat_after_num_plays = 3
        bar.ends_repeat_after_num_plays = nil
        expect(bar).not_to be_ends_repeat
      end

      it "rejects an integer below two" do
        expect { bar.ends_repeat_after_num_plays = 1 }.to raise_error(ArgumentError)
      end

      it "rejects a non-integer" do
        expect { bar.ends_repeat_after_num_plays = 2.5 }.to raise_error(ArgumentError)
      end
    end

    describe "#plays_on_passes=" do
      it "accepts a list of positive integers" do
        bar.plays_on_passes = [1, 2]
        expect(bar.plays_on_passes).to eq [1, 2]
      end

      it "rejects an empty array" do
        expect { bar.plays_on_passes = [] }.to raise_error(ArgumentError)
      end

      it "rejects duplicate passes" do
        expect { bar.plays_on_passes = [1, 1] }.to raise_error(ArgumentError)
      end

      it "rejects non-positive passes" do
        expect { bar.plays_on_passes = [0, 1] }.to raise_error(ArgumentError)
      end

      it "rejects non-integer passes" do
        expect { bar.plays_on_passes = [1, "2"] }.to raise_error(ArgumentError)
      end
    end

    describe "#plays_on_pass?" do
      before { bar.plays_on_passes = [1, 3] }

      it "returns true for a listed pass" do
        expect(bar.plays_on_pass?(3)).to be true
      end

      it "returns false for an unlisted pass" do
        expect(bar.plays_on_pass?(2)).to be false
      end
    end

    describe "#to_s" do
      before do
        bar.starts_repeat = true
        bar.ends_repeat_after_num_plays = 2
      end

      it "includes the repeat state" do
        expect(bar.to_s).to eq "Bar |: :|x2"
      end
    end
  end

  describe "#to_h" do
    it "returns an empty hash for a default bar" do
      expect(bar.to_h).to eq({})
    end

    it "serializes the key signature by its parseable name" do
      bar.key_signature = "F# minor"
      expect(bar.to_h).to eq("key_signature" => "F♯ minor")
    end

    it "serializes the meter" do
      bar.meter = "6/8"
      expect(bar.to_h).to eq("meter" => "6/8")
    end

    context "with repeat structure" do
      before do
        bar.starts_repeat = true
        bar.ends_repeat_after_num_plays = 2
        bar.plays_on_passes = [1, 2]
      end

      it "serializes the repeat structure" do
        expect(bar.to_h).to eq(
          "starts_repeat" => true,
          "ends_repeat_after_num_plays" => 2,
          "plays_on_passes" => [1, 2]
        )
      end
    end

    it "includes only the keys that are set" do
      bar.meter = "3/4"
      bar.starts_repeat = true
      expect(bar.to_h.keys).to contain_exactly("meter", "starts_repeat")
    end
  end
end
