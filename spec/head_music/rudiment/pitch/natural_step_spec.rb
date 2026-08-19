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

  describe "#applied_to" do
    def pitch(name)
      HeadMusic::Rudiment::Pitch.get(name)
    end

    it "keeps the register when the step stays inside the octave" do
      expect(step("C", 2).applied_to(pitch("C4")).to_s).to eq "E4"
    end

    it "takes its register from the pitch rather than the letter name" do
      expect(step("C", 2).applied_to(pitch("C7")).to_s).to eq "E7"
    end

    it "climbs a register when the letters wrap upward past B" do
      expect(step("A", 2).applied_to(pitch("A4")).to_s).to eq "C5"
    end

    it "drops a register when the letters wrap downward past C" do
      expect(step("C", -1).applied_to(pitch("C4")).to_s).to eq "B3"
    end

    it "drops the alteration, landing on the natural letter" do
      expect(step("C", 1).applied_to(pitch("C#4")).to_s).to eq "D4"
    end
  end
end
