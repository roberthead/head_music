require "spec_helper"

describe HeadMusic::Analysis::KeyFinder::Histograms do
  subject(:histograms) { described_class.new(HeadMusic::Analysis::NoteInput.for(notes, meter: "4/4")) }

  let(:notes) { [[60, 0, 3r / 2], [67, 3r / 2, 1r / 2], [62, 2, 1]] }

  def weights(histogram)
    histogram.each_with_index.reject { |weight, _| weight.zero? }.to_h { |weight, pitch_class| [pitch_class, weight] }
  end

  describe "#whole" do
    it "weighs each pitch class by its duration" do
      expect(weights(histograms.whole)).to eq(0 => 3r / 2, 7 => 1r / 2, 2 => 1r)
    end
  end

  describe "#by_bar" do
    it "credits a note to each bar it sounds in" do
      expect(histograms.by_bar.map { |histogram| weights(histogram) }).to eq [{0 => 1r}, {0 => 1r / 2, 7 => 1r / 2}, {2 => 1r}]
    end
  end

  describe "#windowed" do
    it "sums each bar with the bars on either side" do
      expect(histograms.windowed(1).map { |histogram| weights(histogram) })
        .to eq [{0 => 3r / 2, 7 => 1r / 2}, {0 => 3r / 2, 7 => 1r / 2, 2 => 1r}, {0 => 1r / 2, 7 => 1r / 2, 2 => 1r}]
    end

    it "answers each bar alone with no window" do
      expect(histograms.windowed(0)).to eq histograms.by_bar
    end
  end
end
