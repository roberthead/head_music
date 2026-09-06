require "spec_helper"

describe HeadMusic::Content::Bar do
  subject(:bar) { flow.bars(2).last }

  let(:flow) { HeadMusic::Content::Flow.new(key_signature: "D major", meter: "6/8") }

  its(:number) { is_expected.to eq 2 }

  # A bar reports the change authored in it, not the value in force there --
  # so a bar in a flow that merely opens in 6/8 reports no meter at all.
  its(:key_signature) { is_expected.to be_nil }
  its(:meter) { is_expected.to be_nil }

  describe "the key signature authored here" do
    before { flow.change_key_signature(2, "F# minor") }

    it "is a key signature" do
      expect(bar.key_signature).to be_a(HeadMusic::Rudiment::KeySignature)
    end

    it "is the one that was authored" do
      expect(bar.key_signature).to eq "F# minor"
    end

    it "leaves neighbouring bars reporting no change" do
      expect(flow.bars(3).last.key_signature).to be_nil
    end

    it "is still in force in the bars that follow" do
      expect(flow.key_signature_at(3)).to eq "F# minor"
    end
  end

  describe "the meter authored here" do
    before { flow.change_meter(2, "5/4") }

    it "is a meter" do
      expect(bar.meter).to be_a(HeadMusic::Rudiment::Meter)
    end

    it "is the one that was authored" do
      expect(bar.meter).to eq "5/4"
    end

    its(:to_s) { is_expected.to eq "Bar 5/4" }

    it "leaves neighbouring bars reporting no change" do
      expect(flow.bars(3).last.meter).to be_nil
    end

    it "is still in force in the bars that follow" do
      expect(flow.meter_at(3)).to eq "5/4"
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

    # Key and meter changes belong to the flow's timeline. A bar reports the
    # ones authored in it, but does not serialize them -- a bar's own state is
    # its repeat structure.
    it "leaves the key signature to the timeline" do
      flow.change_key_signature(2, "F# minor")
      expect(bar.to_h).to eq({})
    end

    it "leaves the meter to the timeline" do
      flow.change_meter(2, "6/8")
      expect(bar.to_h).to eq({})
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
      bar.starts_repeat = true
      expect(bar.to_h.keys).to contain_exactly("starts_repeat")
    end
  end
end
