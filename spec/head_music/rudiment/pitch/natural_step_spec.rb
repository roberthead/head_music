require "spec_helper"

describe HeadMusic::Rudiment::Pitch::NaturalStep do
  def step(letter, num_steps)
    described_class.new(HeadMusic::Rudiment::LetterName.get(letter), num_steps)
  end

  describe "#target_letter_name" do
    it "stays put for zero steps" do
      expect(step("C", 0).target_letter_name.to_s).to eq "C"
    end

    it "moves up within the octave" do
      expect(step("C", 2).target_letter_name.to_s).to eq "E"
    end

    it "wraps the letter cycle moving up past B" do
      expect(step("G", 3).target_letter_name.to_s).to eq "C"
    end

    it "moves down within the octave" do
      expect(step("E", -2).target_letter_name.to_s).to eq "C"
    end
  end

  describe "#octaves_delta" do
    it "is zero within the same octave" do
      expect(step("C", 2).octaves_delta).to eq 0
    end

    it "counts a full octave up" do
      expect(step("C", 7).octaves_delta).to eq 1
    end

    it "adds an octave when the letters wrap upward past B" do
      expect(step("G", 3).octaves_delta).to eq 1
    end

    it "counts a full octave down" do
      expect(step("C", -7).octaves_delta).to eq(-1)
    end

    it "subtracts an octave when the letters wrap downward past C" do
      expect(step("C", -1).octaves_delta).to eq(-1)
    end
  end
end
