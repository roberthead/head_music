require "spec_helper"

describe HeadMusic::Style::Guidelines::AllowFreeSpeciesRhythmicValues do
  def line(abc)
    HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:C\n#{abc}\n").voices.first
  end

  def marked_positions(abc, **config)
    assess(described_class, line(abc), **config).marks.map { |mark| mark.start_position.to_s }.uniq
  end

  it "allows a whole note in any bar" do
    expect(marked_positions("c4|d2 e2|f4|e4|]")).to be_empty
  end

  it "keeps the rest of fifth species, marking an unpaired eighth" do
    expect(marked_positions("c2 d e/ f/|e d e/ f|g4|]")).to eq ["2:3:000"]
  end

  describe "dotted rhythms" do
    let(:dotted_half) { "c3 d|e4|]" }
    let(:dotted_quarter_and_stepping_eighth) { "c2 d3/2 e/|f4|]" }
    let(:dotted_quarter_and_leaping_eighth) { "c2 d3/2 e/|a4|]" }

    it "marks a dotted half by default" do
      expect(marked_positions(dotted_half)).to eq ["1:1:000"]
    end

    it "allows a dotted half with dotted_rhythms" do
      expect(marked_positions(dotted_half, dotted_rhythms: true)).to be_empty
    end

    it "marks a dotted quarter and its eighth by default" do
      expect(marked_positions(dotted_quarter_and_stepping_eighth).length).to eq 2
    end

    it "allows a dotted quarter and an eighth stepping on, with dotted_rhythms" do
      expect(marked_positions(dotted_quarter_and_stepping_eighth, dotted_rhythms: true)).to be_empty
    end

    it "marks a dotted quarter whose eighth leaps on, even with dotted_rhythms" do
      expect(marked_positions(dotted_quarter_and_leaping_eighth, dotted_rhythms: true).length).to eq 2
    end

    it "marks a dotted eighth, even with dotted_rhythms" do
      expect(marked_positions("c2 d d3/4 e/4|f4|]", dotted_rhythms: true)).not_to be_empty
    end

    it "still counts the eighth after a dotted quarter toward the bar's eighths" do
      expect(marked_positions("c3/2 d/ e/ f/ g|a4|]", dotted_rhythms: true)).not_to be_empty
    end
  end

  describe "wording" do
    it "names the dotted rhythms in the instruction when they are allowed" do
      expect(described_class.render_instruction(dotted_rhythms: true)).to include("dotted quarter")
      expect(described_class.render_instruction({})).not_to include("dotted")
    end

    it "names them in the violation too" do
      expect(described_class.render_violation(dotted_rhythms: true)).to include("dotted quarter")
    end
  end
end
