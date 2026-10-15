require "spec_helper"

describe HeadMusic::Notation::Kern::TupletGroups do
  # Each field is a kern duration, read from a note token.
  def items(*durations)
    durations.map { |duration| described_class.item(HeadMusic::Notation::Kern::TokenReader.read("#{duration}c").rhythmic_value) }
  end

  describe ".runs" do
    it "closes three triplet eighths at a quarter" do
      expect(described_class.runs(items("12", "12", "12"))).to eq [0..2]
    end

    it "closes a dotted value, its fill, and a third value at the first plain sum" do
      expect(described_class.runs(items("12.", "24", "12"))).to eq [0..2]
    end

    it "reads six triplet sixteenths as two triplets" do
      expect(described_class.runs(items("24", "24", "24", "24", "24", "24"))).to eq [0..2, 3..5]
    end

    it "closes a quintuplet and a septuplet at their quarters" do
      expect(described_class.runs(items(*%w[20 20 20 20 20], *%w[28 28 28 28 28 28 28]))).to eq [0..4, 5..11]
    end

    it "needs at least two values, so a lone dotted triplet quarter stays ungrouped" do
      expect(described_class.runs(items("6.", "4"))).to eq []
    end

    it "leaves a run that never fills ungrouped" do
      expect(described_class.runs(items("12", "12", "4", "12"))).to eq []
    end

    it "ends a run at a value of another ratio" do
      expect(described_class.runs(items("12", "12", "20", "12"))).to eq []
    end

    it "starts again after a run that never fills" do
      expect(described_class.runs(items("12", "12", "4", "12", "12", "12"))).to eq [3..5]
    end

    it "leaves a leftover value after a group ungrouped" do
      expect(described_class.runs(items("12", "12", "12", "12", "4"))).to eq [0..2]
    end
  end

  describe ".apply" do
    let(:voice) { HeadMusic::Content::Flow.new(meter: "4/4").add_voice }
    let(:triplet) { HeadMusic::Rudiment::RhythmicValue.get(:eighth, tuplet: "3:2") }

    before do
      [[triplet.append_tied(triplet), "C4"], [triplet, nil], [:half, "D4"], [:quarter, "E4"]].each do |value, sounds|
        voice.place(voice.next_position, value, sounds)
      end
    end

    it "groups a run of tied chains and rests" do
      described_class.apply(voice)
      expect(voice.tuplets.map(&:to_s)).to eq ["3:2 tuplet from 1:1:000 to 1:2:000"]
    end

    it "leaves a run the voice refuses ungrouped" do
      described_class.apply(voice)
      expect { described_class.apply(voice) }.not_to change { voice.tuplets.length }
    end
  end
end
