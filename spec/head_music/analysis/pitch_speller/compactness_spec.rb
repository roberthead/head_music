require "spec_helper"

describe HeadMusic::Analysis::PitchSpeller::Compactness do
  let(:c_sharp_or_d_flat) { [7, -5] }
  let(:g_sharp_or_a_flat) { [8, -4] }

  describe "#choices" do
    it "narrows the span around the notes held fixed" do
      choices = described_class.new([c_sharp_or_d_flat, g_sharp_or_a_flat], [2, 2], [-1]).choices
      expect(choices).to eq [[-5, :sonority], [-4, :sonority]]
    end

    it "answers the center where the narrowest spans disagree" do
      expect(described_class.new([c_sharp_or_d_flat], [2], []).choices).to eq [[7, :center]]
    end

    it "answers each doubling as its pitch class is settled" do
      pairs = [c_sharp_or_d_flat, g_sharp_or_a_flat, c_sharp_or_d_flat]
      expect(described_class.new(pairs, [2, 2, 2], [-1]).choices).to eq [[-5, :sonority], [-4, :sonority], [-5, :sonority]]
    end

    it "weighs each combination of distinct pairs once, however many octave doublings there are" do
      compactness = described_class.new([c_sharp_or_d_flat] * 6 + [g_sharp_or_a_flat] * 6, [2] * 12, [-1])
      allow(compactness).to receive(:span).and_call_original
      compactness.choices
      expect(compactness).to have_received(:span).exactly(4).times
    end
  end
end
