require "spec_helper"

describe HeadMusic::Style::Guidelines::ClausulaVera do
  def flow_for(upper:, lower:, key: "Ddor")
    HeadMusic::Notation::ABC.parse(<<~ABC)
      X:1
      M:4/4
      L:1/4
      K:#{key}
      V:upper
      #{upper}
      V:lower
      #{lower}
    ABC
  end

  def assessments(flow)
    flow.voices.map { |voice| assess(described_class, voice) }
  end

  shared_examples "a clausula vera" do
    it "marks neither voice" do
      expect(assessments(flow)).to all(be_adherent)
    end
  end

  context "with the raised leading tone in the upper voice" do
    let(:flow) { flow_for(upper: "a4|^c4|d4|]", lower: "F4|E4|D4|]") }

    it_behaves_like "a clausula vera"
  end

  context "with the raised leading tone in the lower voice" do
    let(:flow) { flow_for(upper: "f4|e4|d4|]", lower: "A,4|^C4|D4|]") }

    it_behaves_like "a clausula vera"
  end

  context "with the leading tone attacked on beat 3 against the second degree" do
    let(:flow) { flow_for(upper: "a4|d2 ^c2|d4|]", lower: "F4|E4|D4|]") }

    it_behaves_like "a clausula vera"
  end

  context "with an unraised seventh in Dorian" do
    let(:flow) { flow_for(upper: "a4|c4|d4|]", lower: "F4|E4|D4|]") }

    it "marks the cadence in both voices" do
      expect(assessments(flow).map(&:adherent?)).to eq [false, false]
    end

    it "asks for the raise" do
      expect(assessments(flow).first.message).to include("Raise the leading tone")
    end
  end

  context "with Phrygian's whole step from the seventh against the half step from the second" do
    let(:flow) { flow_for(upper: "c4|d4|e4|]", lower: "A,4|F4|E4|]", key: "Ephr") }

    it_behaves_like "a clausula vera"
  end

  context "with a raised seventh in Phrygian" do
    let(:flow) { flow_for(upper: "c4|^d4|e4|]", lower: "A,4|F4|E4|]", key: "Ephr") }

    it "marks the cadence" do
      expect(assessments(flow).first).not_to be_adherent
    end
  end

  context "with a minor key" do
    let(:flow) { flow_for(upper: "c4|^c4|d4|]", lower: "F4|E4|D4|]", key: "Dm") }

    it_behaves_like "a clausula vera"
  end

  context "with a major key, where the seventh is already a half step below" do
    let(:flow) { flow_for(upper: "e4|B4|c4|]", lower: "C4|D4|C4|]", key: "C") }

    it_behaves_like "a clausula vera"
  end

  context "with both voices stepping the same way into the final" do
    let(:flow) { flow_for(upper: "f4|e4|d4|]", lower: "D4|E4|D4|]") }

    it "marks the cadence with the clausula vera message" do
      expect(assessments(flow).first.message).to include("Close with the clausula vera")
    end
  end

  context "with the authentic cadence's 5 to 1 in the lower voice" do
    let(:flow) { flow_for(upper: "f4|^c4|d4|]", lower: "D4|A,4|D,4|]") }

    it "marks the cadence" do
      expect(assessments(flow).map(&:adherent?)).to eq [false, false]
    end
  end

  context "with a final fifth instead of an octave" do
    let(:flow) { flow_for(upper: "f4|e4|a4|]", lower: "A,4|^C4|D4|]") }

    it "marks the cadence" do
      expect(assessments(flow).first).not_to be_adherent
    end
  end

  context "with no other voice" do
    let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:Ddor\nf4|e4|d4|]\n") }

    it "marks nothing" do
      expect(assess(described_class, flow.voices.first)).to be_adherent
    end
  end

  describe ".with" do
    it "defaults to the clausula vera" do
      expect(described_class.with.config).to eq(forms: [:clausula_vera])
    end

    it "names a form it does not yet support" do
      expect { described_class.with(forms: [:authentic]) }
        .to raise_error(ArgumentError, /does not yet support the authentic cadence form/)
    end
  end
end
