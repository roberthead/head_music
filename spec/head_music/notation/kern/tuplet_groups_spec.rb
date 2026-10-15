require "spec_helper"

describe HeadMusic::Notation::Kern::TupletGroups do
  # Each field is a kern duration, read from a note token, and one voice event.
  def items(*durations)
    durations.each_with_index.flat_map do |duration, event|
      described_class.items_of(HeadMusic::Notation::Kern::TokenReader.read("#{duration}c").rhythmic_value, event)
    end
  end

  def value(name)
    HeadMusic::Rudiment::RhythmicValue.get(name)
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

    it "closes a group on the first link of a chain that mixes ratios" do
      chain = described_class.items_of(value("triplet eighth tied to quarter"), 2)
      expect(described_class.runs(items("12", "12") + chain)).to eq [0..2]
    end

    it "opens a group on a later link of a chain" do
      chain = described_class.items_of(value("quarter tied to triplet eighth"), 0)
      expect(described_class.runs(chain + items("12", "12").map { |item| item.with(event: item.event + 1) })).to eq [1..3]
    end

    it "keeps a triplet whose middle note is split at a barline as one group" do
      chain = described_class.items_of(value("triplet eighth tied to triplet eighth"), 1)
      expect(described_class.runs(items("6") + chain + items("6").map { |item| item.with(event: 2) })).to eq [0..3]
    end

    it "needs links of two voice events, so a tied chain alone stays ungrouped" do
      expect(described_class.runs(described_class.items_of(value("triplet quarter tied to triplet eighth"), 0))).to eq []
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

    it "groups a triplet ending in a chain that mixes ratios across a barline" do
      flow = HeadMusic::Notation::Kern.parse("**kern\n*M4/4\n=1\n2.r\n12d\n12e\n[12f\n=2\n4f]\n2.r\n==\n*-\n")
      expect(flow.voices.first.tuplets.map(&:to_s)).to eq ["3:2 tuplet from 1:4:000 to 2:1:000"]
    end

    it "leaves a run the voice refuses ungrouped" do
      described_class.apply(voice)
      expect { described_class.apply(voice) }.not_to change { voice.tuplets.length }
    end
  end
end
