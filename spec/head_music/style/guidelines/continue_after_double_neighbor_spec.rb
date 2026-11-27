require "spec_helper"

describe HeadMusic::Style::Guidelines::ContinueAfterDoubleNeighbor do
  subject(:assessment) { assess(described_class, graded_voice, tier: :secondary) }

  let(:flow) do
    HeadMusic::Notation::ABC.parse(<<~ABC)
      X:1
      M:4/4
      L:1/4
      K:C
      V:upper
      #{upper}
      V:lower
      #{lower}
    ABC
  end
  let(:graded_voice) { flow.voices.first }

  context "with the upper neighbor first" do
    context "when the line steps on in the direction of the last step" do
      let(:upper) { "e f d e|f4|]" }
      let(:lower) { "C4|D4|]" }

      it { is_expected.to be_adherent }
    end

    context "when the line steps back" do
      let(:upper) { "e f d e|d4|]" }
      let(:lower) { "C4|B,4|]" }

      it "marks the last note of the figure and the note that leaves it" do
        expect(assessment.marks.map { |mark| [mark.start_position.to_s, mark.end_position.to_s] })
          .to eq [["1:4:000", "3:1:000"]]
      end
    end

    context "when the line leaps on in the direction of the last step" do
      let(:upper) { "e f d e|g4|]" }
      let(:lower) { "C4|E4|]" }

      it { expect(assessment.marks_count).to eq 1 }
    end

    context "when the last note is repeated" do
      let(:upper) { "e f d e|e4|]" }
      let(:lower) { "C4|C4|]" }

      it { expect(assessment.marks_count).to eq 1 }
    end

    context "when the figure ends the line" do
      let(:upper) { "e f d e|]" }
      let(:lower) { "C4|]" }

      it { is_expected.to be_adherent }
    end
  end

  context "with the lower neighbor first" do
    context "when the line steps on in the direction of the last step" do
      let(:upper) { "e d f e|d4|]" }
      let(:lower) { "C4|B,4|]" }

      it { is_expected.to be_adherent }
    end

    context "when the line steps back" do
      let(:upper) { "e d f e|f4|]" }
      let(:lower) { "C4|D4|]" }

      it { expect(assessment.marks_count).to eq 1 }
    end

    context "when the line leaps on" do
      let(:upper) { "e d f e|g4|]" }
      let(:lower) { "C4|E4|]" }

      it { expect(assessment.marks_count).to eq 1 }
    end
  end

  context "when the first note is tied over the barline and the line leaps on" do
    let(:upper) { "g2 e2-|e f d e|g4|]" }
    let(:lower) { "C4|C4|E4|]" }

    it { expect(assessment.marks_count).to eq 1 }
  end

  # The dissonance guidelines refuse these shapes as double neighbors, so
  # their leaps away are not graded as leaving one.
  context "with a shape the dissonance guidelines do not read as a double neighbor" do
    context "when it begins on the second beat" do
      let(:upper) { "g e f d|e4|g4|]" }
      let(:lower) { "C4|C4|E4|]" }

      it { is_expected.to be_adherent }
    end

    context "when it begins on the third beat" do
      let(:upper) { "g2 e f|d e g2|]" }
      let(:lower) { "C4|C2 E2|]" }

      it { is_expected.to be_adherent }
    end

    context "when it is in half notes" do
      let(:upper) { "e2 f2|d2 e2|a4|]" }
      let(:lower) { "C4|C4|D4|]" }

      it { is_expected.to be_adherent }
    end

    context "when it mixes half notes and quarters" do
      let(:upper) { "e2 f d|e2 a2|]" }
      let(:lower) { "C4|C2 D2|]" }

      it { is_expected.to be_adherent }
    end

    context "when it is in eighth notes from the downbeat" do
      let(:upper) { "e/ f/ d/ e/ g2|c'4|]" }
      let(:lower) { "C4|C4|]" }

      it { is_expected.to be_adherent }
    end
  end

  context "when the continuation is a half note" do
    let(:lower) { "C4|D4|]" }

    context "with a step on" do
      let(:upper) { "e f d e|f2 a2|]" }

      it { is_expected.to be_adherent }
    end

    context "with a leap" do
      let(:upper) { "e f d e|a2 f2|]" }

      it { expect(assessment.marks_count).to eq 1 }
    end
  end

  # Fux figure 55 bar 8 has this shape on beats 2 to 4 and leaps away. Its
  # first note is dissonant, so nothing is being decorated.
  context "with the shape of a double neighbor on a dissonant note" do
    let(:upper) { "d e c d|g4|]" }
    let(:lower) { "C4|C4|]" }

    it { is_expected.to be_adherent }
  end

  # The opening of Fux's C ionian cantus firmus has this shape in whole
  # notes. Nothing in it is dissonant, so there is no figure to leave.
  context "with the shape of a double neighbor whose notes are all consonant" do
    let(:upper) { "c'4|b4|d'4|c'4|e'4|]" }
    let(:lower) { "E4|G4|F4|E4|C4|]" }

    it { is_expected.to be_adherent }
  end

  context "with no other voice" do
    let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:C\ne f d e|g4|]") }

    it { is_expected.to be_adherent }
  end

  # Salzer and Schachter, Counterpoint in Composition, Example 3-19 (p. 62):
  # a and b "good", c and d "less good".
  describe "Salzer and Schachter's Example 3-19" do
    let(:graded_voice) { flow.voices.last }

    {
      "a" => ["e4|f4|]", "C D B, C|D4|]", 0],
      "b" => ["e4|d4|]", "C B, D C|B,4|]", 0],
      "c" => ["e4|d4|]", "C D B, C|F4|]", 1],
      "d" => ["E4|F4|]", "C D B, C|A,4|]", 1]
    }.each do |letter, (cantus, counterpoint, marks_count)|
      context "with progression #{letter}" do
        let(:upper) { cantus }
        let(:lower) { counterpoint }

        it { expect(assessment.marks_count).to eq marks_count }
      end
    end
  end
end
