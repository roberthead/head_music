require "spec_helper"

describe HeadMusic::Style::Guideline::ConsonantRun do
  subject(:run) do
    described_class.new(
      line: line.notes,
      note: line.notes[1],
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
  let(:lower) { "C4|C4|]" }

  context "with a dissonance stepping on in one direction" do
    let(:upper) { "e f g2|e4|]" }

    it { is_expected.to be_passing }
    it { is_expected.not_to be_returning }
  end

  context "with two dissonances stepping on in one direction" do
    let(:upper) { "g f e d|c4|]" }
    let(:lower) { "B,4|C4|]" }

    it { is_expected.to be_passing }
  end

  context "with a dissonance stepping back to the note before it" do
    let(:upper) { "e f e2|e4|]" }

    it { is_expected.to be_returning }
    it { is_expected.not_to be_passing }
  end

  # F is a fourth over C and is left by a third.
  context "with a dissonance left by leap" do
    let(:upper) { "e f a2|e4|]" }

    it { is_expected.not_to be_passing }
    it { is_expected.not_to be_returning }
  end

  context "with a rest after the dissonance" do
    let(:upper) { "e f z g|e4|]" }

    it "breaks the run at the rest" do
      expect(run).not_to be_passing
    end
  end

  # D and F are a ninth and a fourth over C, and no consonance precedes them.
  context "with no consonant note before the dissonance" do
    let(:upper) { "d f g2|e4|]" }

    it { is_expected.not_to be_passing }
    it { is_expected.not_to be_returning }
  end
end
