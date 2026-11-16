require "spec_helper"

describe HeadMusic::Style::Guidelines::BarCount do
  # Eight bars in the upper voice; the lower voice enters a bar late.
  let(:flow) do
    HeadMusic::Notation::ABC.parse(<<~ABC)
      X:1
      M:4/4
      L:1/4
      K:C
      V:upper
      e4|f4|g4|a4|g4|f4|d4|c4|]
      V:lower
      z4|D4|E4|F4|E4|D4|B,4|C4|]
    ABC
  end
  let(:upper) { flow.voices.first }
  let(:lower) { flow.voices.last }

  def assessment(bars, voice = upper)
    described_class.with(bars).assess(voice, :secondary)
  end

  describe "within the limits" do
    [8, 8..12, 8.., ..8, 6...9].each do |bars|
      it "accepts eight bars for #{bars.inspect}" do
        expect(assessment(bars)).to be_adherent
      end
    end

    it "counts from the first entry of either voice, so a staggered entry is no missing bar" do
      expect(assessment(8, lower)).to be_adherent
    end
  end

  describe "a short passage" do
    it "marks every note with fitness actual over minimum" do
      result = assessment(10..)
      expect(result.marks.length).to eq 1
      expect(result.fitness).to be_within(0.0001).of(0.8)
    end

    it "reads an exclusive range's end as one bar less" do
      expect(assessment(9...12)).not_to be_adherent
      expect(assessment(..9)).to be_adherent
      expect(assessment(...8)).not_to be_adherent
    end
  end

  describe "a long passage" do
    it "marks the notes in the bars past the limit" do
      result = assessment(..6)
      expect(result.marks.map { |mark| mark.start_position.bar_number }).to eq [7, 8]
    end

    it "scores the overage by its share of the voice's notes" do
      expect(assessment(..6).fitness).to be > assessment(..4).fitness
    end
  end

  describe ".with" do
    it "reads an Integer as an exact count" do
      expect(described_class.with(8).config).to eq(bars: 8..8)
    end

    it "rejects anything else" do
      expect { described_class.with("eight") }.to raise_error(ArgumentError, /Integer or a Range/)
    end
  end

  describe "wording" do
    {
      8 => "Write eight bars.",
      1 => "Write one bar.",
      (8..) => "Write at least eight bars.",
      (..12) => "Write no more than twelve bars.",
      (8...13) => "Write between eight and twelve bars."
    }.each do |bars, sentence|
      it "says #{sentence.inspect} for #{bars.inspect}" do
        expect(described_class.with(bars).instruction).to eq sentence
      end
    end
  end
end
