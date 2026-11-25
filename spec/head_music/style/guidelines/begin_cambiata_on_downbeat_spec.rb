require "spec_helper"

describe HeadMusic::Style::Guidelines::BeginCambiataOnDownbeat do
  subject(:assessment) { assess(described_class, graded_voice, tier: :secondary) }

  let(:meter) { "4/4" }
  let(:flow) do
    HeadMusic::Notation::ABC.parse(<<~ABC)
      X:1
      M:#{meter}
      L:1/4
      K:C
      V:upper
      #{upper}
      V:lower
      #{lower}
    ABC
  end
  let(:graded_voice) { flow.voices.first }

  def mark_spans
    assessment.marks.map { |mark| [mark.start_position.to_s, mark.end_position.to_s] }
  end

  context "with a cambiata begun on the downbeat" do
    let(:upper) { "c' b g a|b4|]" }
    let(:lower) { "C4|G,4|]" }

    it { is_expected.to be_adherent }
  end

  context "with a cambiata begun on beat 3" do
    let(:upper) { "e2 c' b|g a b2|]" }
    let(:lower) { "C4|E4|]" }

    it "marks the five notes of the figure once" do
      expect(mark_spans).to eq [["1:3:000", "3:1:000"]]
    end

    it "is a weak preference" do
      expect(described_class.strength).to eq :weak
    end
  end

  # B is a seventh over C on beat 3. The dissonance guideline marks it, since
  # a figure begun on a weak beat is no cambiata.
  context "with the shape begun on beat 2" do
    let(:upper) { "e c' b g|a b d'2|]" }
    let(:lower) { "C4|D4|]" }

    it { is_expected.to be_adherent }
  end

  # Fux's figure 87a.
  context "with a first note attacked on beat 3 and tied over, and the dissonance on beat 2" do
    let(:upper) { "z2 c'2-|c' b g a|b4|]" }
    let(:lower) { "C4|C4|G,4|]" }

    it { is_expected.to be_adherent }
  end

  # B is a fifth over E, so the shape excuses nothing and is no figure.
  context "with the shape begun on beat 3 and a consonant second note" do
    let(:upper) { "e2 c' b|g a b2|]" }
    let(:lower) { "E4|E4|]" }

    it { is_expected.to be_adherent }
  end

  # The eighth-note B follows beat 3. The dissonance guidelines of fifth and
  # free species refuse it for its value, and one fault is marked once.
  context "with a cambiata begun on beat 3 whose dissonance is an eighth note" do
    let(:upper) { "e2 c'/ b/ g|a b3|]" }
    let(:lower) { "C4|D4|]" }

    it { is_expected.to be_adherent }
  end

  context "with a cambiata from the downbeat whose dissonance is a half note" do
    let(:upper) { "c'2 b2|g a b2|]" }
    let(:lower) { "C4|E4|]" }

    it { is_expected.to be_adherent }
  end

  context "when in cut time" do
    let(:meter) { "2/2" }

    context "with a cambiata begun on the downbeat" do
      let(:upper) { "c' b g a|b4|]" }
      let(:lower) { "C4|G,4|]" }

      it { is_expected.to be_adherent }
    end

    context "with a cambiata begun on the second half note" do
      let(:upper) { "e2 c' b|g a b2|]" }
      let(:lower) { "C4|E4|]" }

      it { expect(mark_spans).to eq [["1:2:000", "3:1:000"]] }
    end
  end

  context "with a cambiata begun on beat 3 in the lower voice of a free pair" do
    let(:upper) { "e4|d4|]" }
    let(:lower) { "E2 C B,|G, A, B,2|]" }

    it "marks the voice that carries the figure" do
      expect(assess(described_class, flow.voices.last, tier: :secondary).marks_count).to eq 1
    end

    it "does not mark the other voice" do
      expect(assessment).to be_adherent
    end
  end

  context "with no other voice" do
    let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:C\ne2 c' b|g a b2|]") }

    it { is_expected.to be_adherent }
  end
end
