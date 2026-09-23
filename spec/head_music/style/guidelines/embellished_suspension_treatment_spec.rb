require "spec_helper"

describe HeadMusic::Style::Guidelines::EmbellishedSuspensionTreatment do
  subject(:guideline) { assess(described_class, counterpoint) }

  # Four bars of Fux's D dorian cantus; the suspension under test is D5 held
  # from bar 2 into bar 3, a seventh over E4 that resolves to C5.
  def counterpoint_over(cantus_firmus, abc, meter: "4/4")
    HeadMusic::Notation::ABC.parse(
      species_abc(source: "example", meter: meter, cantus_firmus: cantus_firmus, counterpoint: abc)
    ).counterpoint_voice
  end

  let(:counterpoint) { counterpoint_over("D4|F4|E4|D4|]", abc) }

  context "with no suspensions" do
    let(:abc) { "z2 A2|A2 c2|c2 B2|A4|]" }

    it { is_expected.to be_adherent }
  end

  context "with a plain suspension resolving on beat three" do
    let(:abc) { "z2 A2|A2 d2-|d2 c2|A4|]" }

    it { is_expected.to be_adherent }
  end

  context "with the resolution anticipated on beat two and repeated on beat three" do
    let(:abc) { "z2 A2|A2 d2-|d c c2|A4|]" }

    it { is_expected.to be_adherent }
  end

  context "with the resolution anticipated on beat two and held through beat three" do
    let(:abc) { "z2 A2|A2 d2-|d c3|A4|]" }

    it { is_expected.to be_adherent }
  end

  context "with the anticipated resolution decorated by an eighth-note lower neighbor" do
    let(:abc) { "z2 A2|A2 d2-|d c/2 B/2 c2|A4|]" }

    it { is_expected.to be_adherent }
  end

  context "with a dissonant eighth-note lower neighbor" do
    let(:abc) { "z2 F2|F2 A2-|A G/2 F/2 G2|A4|]" }

    it { is_expected.to be_adherent }
  end

  context "with an escape tone stepping up on beat two" do
    let(:abc) { "z2 A2|A2 d2-|d e c2|A4|]" }

    it { is_expected.to be_adherent }
  end

  context "with a consonant leap on beat two before the resolution" do
    let(:abc) { "z2 A2|A2 d2-|d B c2|A4|]" }

    it { is_expected.to be_adherent }
  end

  context "with the resolution delayed by one consonant note" do
    let(:abc) { "z2 A2|A2 d2-|d G c2|A4|]" }

    it { is_expected.to be_adherent }
  end

  context "with Fux's fifth-species line" do
    let(:counterpoint) { fux_fifth_species_examples.first.counterpoint_voice }

    it { is_expected.to be_adherent }
  end

  context "when the suspension leaps away and never resolves" do
    let(:abc) { "z2 A2|A2 d2-|d2 B2|A4|]" }

    it { is_expected.not_to be_adherent }

    it "marks the suspended note once" do
      expect(guideline.marks_count).to eq 1
      expect(guideline.fitness).to eq HeadMusic::PENALTY_FACTOR
    end
  end

  context "when the resolution first sounds on beat four" do
    let(:abc) { "z2 A2|A2 d2-|d G G c|A4|]" }

    it "marks the suspended note" do
      expect(guideline.marks_count).to eq 1
    end
  end

  context "when the anticipated resolution is not held on beat three" do
    let(:abc) { "z2 A2|A2 d2-|d c B2|A4|]" }

    it "marks the suspended note" do
      expect(guideline.marks_count).to eq 1
    end
  end

  context "when the suspension is unprepared" do
    let(:abc) { "z2 G2-|G2 F2|E2 c2|A4|]" }

    it "marks the suspended note" do
      expect(guideline.marks_count).to eq 1
    end
  end

  context "when the suspension resolves by ascending step" do
    let(:abc) { "z2 A2|A2 d2-|d2 e2|A4|]" }

    it "marks the suspended note" do
      expect(guideline.marks_count).to eq 1
    end
  end

  context "when the suspension is held through the bar" do
    let(:abc) { "z2 A2|A2 d2-|d4|A4|]" }

    it "marks the suspended note" do
      expect(guideline.marks_count).to eq 1
    end
  end

  # A cantus note that does not last to beat three has no slot to resolve
  # into, so the strict rule applies, as it does for a cantus firmus graded
  # against a florid line.
  context "with the cantus firmus moving before beat three" do
    let(:counterpoint) { counterpoint_over("D4|F4|E2 E2|D4|]", abc) }
    let(:abc) { "z2 A2|A2 d2-|d G c2|A4|]" }

    it "keeps the strict rule" do
      expect(guideline.marks_count).to eq 1
    end
  end

  context "with triple meter" do
    let(:counterpoint) { counterpoint_over("D3|F3|E3|D3|]", abc, meter: "3/4") }

    context "with a plain suspension" do
      let(:abc) { "z A2|A d2-|d c2|A3|]" }

      it { is_expected.to be_adherent }
    end

    context "with a leap before the resolution" do
      let(:abc) { "z A2|A d2-|d G c|A3|]" }

      it "keeps the strict rule" do
        expect(guideline.marks_count).to eq 1
      end
    end
  end

  context "without a cantus firmus" do
    let(:bare_flow) { HeadMusic::Content::Flow.new(key_signature: "D dorian") }
    let(:counterpoint) { bare_flow.add_voice(role: :counterpoint) }

    before { counterpoint.place("1:1", :whole, "A4") }

    it { is_expected.to be_adherent }

    it "produces no marks" do
      expect(guideline.marks).to eq([])
    end
  end
end
