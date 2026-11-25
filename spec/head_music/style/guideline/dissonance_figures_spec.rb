require "spec_helper"

describe HeadMusic::Style::Guideline::DissonanceFigures do
  subject(:figures) do
    described_class.new(
      notes: line.notes,
      melodic_intervals: line.melodic_intervals,
      dissonant: ->(note) { HeadMusic::Analysis::HarmonicInterval.new(other, line, note.position).dissonance?(:two_part_harmony) }
    )
  end

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
  let(:line) { flow.voices.first }
  let(:other) { flow.voices.last }

  context "with a passing tone and a neighbor tone" do
    let(:upper) { "e f g f|e4|]" }
    let(:lower) { "C4|C4|]" }

    it "reads each figure by its shape in the line" do
      expect(figures.passing_tone?(line.notes[1])).to be true
      expect(figures.neighbor_tone?(line.notes[3])).to be false
      expect(figures.neighbor_tone?(line.notes[2])).to be true
    end
  end

  # The consonant notes of a cambiata are read against the other voice where
  # each of them sounds, so a moving companion counts as a held one does.
  context "with a nota cambiata against a moving voice" do
    let(:upper) { "c' b g a|b4|]" }
    let(:lower) { "e2 c2|G4|]" }

    it "recognizes the figure when its outer notes are consonant with the companion there" do
      expect(figures.cambiata_dissonance?(line.notes[1])).to be true
    end
  end

  context "with a nota cambiata whose landing note is dissonant with the moving voice" do
    let(:upper) { "c' b g a|b4|]" }
    let(:lower) { "e2 f2|G4|]" }

    it "does not recognize the figure" do
      expect(figures.cambiata_dissonance?(line.notes[1])).to be false
    end
  end

  describe "#consonant_run?" do
    let(:lower) { "C4|C4|]" }

    context "with a passing tone" do
      let(:upper) { "e f g2|e4|]" }

      it "reads a stepwise run in one direction between consonances" do
        expect(figures.consonant_run?(line.notes[1])).to be true
      end
    end

    context "with a neighbor tone" do
      let(:upper) { "e f e2|e4|]" }

      it "reads a stepwise run returning to its starting pitch" do
        expect(figures.consonant_run?(line.notes[1])).to be true
      end
    end

    context "with a dissonance left by leap" do
      let(:upper) { "e f a2|e4|]" }

      it "does not read a run" do
        expect(figures.consonant_run?(line.notes[1])).to be false
      end
    end

    context "with a rest after the dissonance" do
      let(:upper) { "e f z g|e4|]" }

      it "breaks the run at the rest" do
        expect(figures.consonant_run?(line.notes[1])).to be false
      end
    end
  end

  describe "#passing_run?" do
    let(:lower) { "C4|C4|]" }

    context "with a passing tone" do
      let(:upper) { "e f g2|e4|]" }

      it { expect(figures.passing_run?(line.notes[1])).to be true }
    end

    context "with two dissonances passing in one direction" do
      let(:upper) { "g f e d|c4|]" }
      let(:lower) { "B,4|C4|]" }

      it { expect(figures.passing_run?(line.notes[1])).to be true }
    end

    context "with a neighbor tone" do
      let(:upper) { "e f e2|e4|]" }

      it { expect(figures.passing_run?(line.notes[1])).to be false }
    end

    context "with a dissonance left by leap" do
      let(:upper) { "e f a2|e4|]" }

      it { expect(figures.passing_run?(line.notes[1])).to be false }
    end
  end

  # The fifth note is the cambiata's goal: without two steps back there is no
  # figure, however consonant the note the line reaches instead.
  context "with a nota cambiata that turns back after one step" do
    let(:upper) { "c' b g a|g4|]" }
    let(:lower) { "e2 c2|G4|]" }

    it "does not recognize the figure" do
      expect(figures.cambiata_dissonance?(line.notes[1])).to be false
    end
  end

  context "with a nota cambiata that leaps on after one step" do
    let(:upper) { "c' b g a|d'4|]" }
    let(:lower) { "e2 c2|G4|]" }

    it "does not recognize the figure" do
      expect(figures.cambiata_dissonance?(line.notes[1])).to be false
    end
  end

  context "with a double neighbor" do
    let(:upper) { "g a f g|e4|]" }
    let(:lower) { "C4|C4|]" }

    it "recognizes each member" do
      expect(figures.double_neighbor_member?(line.notes[1])).to be true
      expect(figures.double_neighbor_member?(line.notes[2])).to be true
    end

    it "returns the four notes of the figure" do
      expect(figures.double_neighbors).to eq [line.notes.first(4)]
    end
  end

  context "with the shape of a double neighbor closing on a dissonant note" do
    let(:upper) { "g a f g|e4|]" }
    let(:lower) { "C2 F2|C4|]" }

    it "returns no double neighbor" do
      expect(figures.double_neighbors).to be_empty
    end
  end

  context "with the shape of a double neighbor whose notes are all consonant" do
    let(:upper) { "c'4|b4|d'4|c'4|e'4|]" }
    let(:lower) { "E4|G4|F4|E4|C4|]" }

    it "returns no double neighbor" do
      expect(figures.double_neighbors).to be_empty
    end
  end

  context "with no double neighbor in the line" do
    let(:upper) { "e f g f|e4|]" }
    let(:lower) { "C4|C4|]" }

    it "returns no double neighbor" do
      expect(figures.double_neighbors).to be_empty
    end
  end

  describe "#double_neighbors_with" do
    let(:upper) { "e f d e|c4|]" }
    let(:lower) { "C4|C4|]" }

    it "returns the figure for either neighbor" do
      expect(figures.double_neighbors_with(line.notes[1])).to eq [line.notes[0, 4]]
      expect(figures.double_neighbors_with(line.notes[2])).to eq [line.notes[0, 4]]
    end

    it "returns nothing for the note the figure decorates" do
      expect(figures.double_neighbors_with(line.notes[0])).to be_empty
      expect(figures.double_neighbors_with(line.notes[3])).to be_empty
    end
  end

  describe "#cambiatas" do
    let(:upper) { "c' b g a|b4|]" }

    context "with a dissonant second note" do
      let(:lower) { "C4|G,4|]" }

      it "returns the five notes of the figure" do
        expect(figures.cambiatas).to eq [line.notes[0, 5]]
      end
    end

    # B is a fifth over E.
    context "with a consonant second note" do
      let(:lower) { "E4|G,4|]" }

      it "returns no cambiata" do
        expect(figures.cambiatas).to be_empty
      end
    end
  end

  describe "#escape_tone?" do
    subject(:escape_tone) { figures.escape_tone?(line.notes[1]) }

    let(:lower) { "C4|C4|]" }

    context "with a step up left by a third down" do
      let(:upper) { "a b g e|g4|]" }

      it { is_expected.to be true }

      it "does not recognize the first or the last note of the line" do
        expect(figures.escape_tone?(line.notes.first)).to be false
        expect(figures.escape_tone?(line.notes.last)).to be false
      end
    end

    context "with a step down left by a third up" do
      let(:upper) { "g f a c'|g4|]" }

      it { is_expected.to be true }
    end

    context "with a step followed by a third in the same direction" do
      let(:upper) { "e f a g|g4|]" }

      it { is_expected.to be false }
    end

    context "with a third followed by a third in the opposite direction" do
      let(:upper) { "e g e c|g4|]" }

      it { is_expected.to be false }
    end

    context "with a leap wider than a third" do
      let(:upper) { "c' d' a g|e4|]" }

      it { is_expected.to be false }
    end

    context "with a leap to a dissonant note" do
      let(:upper) { "c' d' b a|g4|]" }

      it { is_expected.to be false }
    end

    context "with a dissonant starting note" do
      let(:upper) { "d' e' c' g|e4|]" }

      it { is_expected.to be false }
    end

    # The second neighbor is consonant here, so only the completed figure
    # tells the first neighbor from an escape tone.
    context "with a double neighbor whose second neighbor is consonant" do
      let(:upper) { "a b g a|g4|]" }

      it { is_expected.to be false }

      it "belongs to the double neighbor" do
        expect(figures.double_neighbor_member?(line.notes[1])).to be true
      end
    end
  end
end
