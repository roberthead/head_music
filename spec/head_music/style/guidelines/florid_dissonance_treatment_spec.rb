require "spec_helper"

describe HeadMusic::Style::Guidelines::FloridDissonanceTreatment do
  subject { described_class.new(counterpoint) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian", meter: "4/4") }
  let(:counterpoint) { composition.add_voice(role: :counterpoint) }
  let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }

  before do
    composition.add_voice(role: :cantus_firmus).tap do |voice|
      cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end
  end

  context "with no notes" do
    it { is_expected.to be_adherent }
  end

  context "with all consonant notes" do
    before do
      # All notes consonant with the CF
      counterpoint.place("1:1", :whole, "A4")
      counterpoint.place("2:1", :whole, "A4")
      counterpoint.place("3:1", :whole, "B4")
      counterpoint.place("4:1", :whole, "A4")
      counterpoint.place("5:1", :whole, "B4")
      counterpoint.place("6:1", :whole, "A4")
      counterpoint.place("7:1", :whole, "C5")
      counterpoint.place("8:1", :whole, "B4")
      counterpoint.place("9:1", :whole, "A4")
      counterpoint.place("10:1", :whole, "B4")
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a passing tone on a weak beat" do
    before do
      # Bar 1: A4 half (P5 with D4, consonant), then B4 half (passing tone, M6 with D4, consonant)
      # Bar 2: A4 whole (M3 with F4, consonant)
      counterpoint.place("1:1", :half, "A4")
      counterpoint.place("1:3", :half, "B4")
      counterpoint.place("2:1", :whole, "A4")
      counterpoint.place("3:1", :whole, "B4")
      counterpoint.place("4:1", :whole, "A4")
      counterpoint.place("5:1", :whole, "B4")
      counterpoint.place("6:1", :whole, "A4")
      counterpoint.place("7:1", :whole, "C5")
      counterpoint.place("8:1", :whole, "B4")
      counterpoint.place("9:1", :whole, "A4")
      counterpoint.place("10:1", :whole, "B4")
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a proper 7-6 suspension in a florid texture" do
    let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4] }

    before do
      # Bar 1: half A4 (P5 with D4, consonant)
      counterpoint.place("1:3", :half, "A4")
      # Bar 2: half A4, then whole D5 starting at 2:3
      # D5 at 2:3 is M6 with CF F4 (consonant = preparation)
      counterpoint.place("2:1", :half, "A4")
      counterpoint.place("2:3", :whole, "D5")
      # D5 sustains into bar 3:1 where CF=E4: m7 (dissonant = suspension)
      # Bar 3: C5 at 3:3 resolves by step down (m6 with CF E4, consonant)
      counterpoint.place("3:3", :half, "C5")
      counterpoint.place("4:1", :whole, "A4")
    end

    it { is_expected.to be_adherent }
  end

  context "with a dissonant note on a strong beat without suspension" do
    let(:cantus_firmus_pitches) { %w[D4 F4 E4] }

    before do
      # E4 is m2 with CF F4 at bar 2 = dissonant on strong beat, not a suspension
      counterpoint.place("1:1", :whole, "A4")
      counterpoint.place("2:1", :whole, "E4")
      counterpoint.place("3:1", :whole, "B4")
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with a dissonant weak-beat note that is neither PT, NT, cambiata, nor double neighbor" do
    let(:cantus_firmus_pitches) { %w[D4 F4 E4] }

    before do
      # Bar 1: A4 (P5, consonant), then leap to E5 (dissonant m2 with CF... wait, no)
      # D4 CF: A4 = P5 consonant. quarter A4, quarter E4 (m2 with D4, dissonant),
      # then leap to A4 -- dissonant E4 leaps out (not a passing tone or neighbor)
      counterpoint.place("1:1", :quarter, "A4")
      counterpoint.place("1:2", :quarter, "E4")
      counterpoint.place("1:3", :quarter, "A4")
      counterpoint.place("1:4", :quarter, "B4")
      counterpoint.place("2:1", :whole, "A4")
      counterpoint.place("3:1", :whole, "B4")
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with a lone dissonant weak-beat note (no surrounding notes)" do
    let(:cantus_firmus_pitches) { %w[D4 F4] }

    before do
      # A single dissonant note (E4 = M2 with CF D4) placed on beat 3.
      # It has neither a preceding nor a following counterpoint note, so it
      # cannot be a passing tone, neighbor, cambiata, or double-neighbor figure.
      counterpoint.place("1:3", :half, "E4")
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "when resolving a strong-beat suspension by step" do
    let(:guideline) { described_class.new(counterpoint) }

    before do
      counterpoint.place("1:1", :quarter, "A4")
      counterpoint.place("1:2", :quarter, "B4")
      counterpoint.place("1:3", :quarter, "E5")
      counterpoint.place("1:4", :quarter, "A4")
    end

    it "resolves by step when the next note steps to a consonance" do
      # A4 -> B4 is a step, and B4 (M6 with CF D4) is consonant.
      expect(guideline.send(:resolved_by_step?, counterpoint.notes[0])).to be true
    end

    it "does not resolve by step when the next note is reached by leap" do
      # B4 -> E5 is a perfect fourth, not a step.
      expect(guideline.send(:resolved_by_step?, counterpoint.notes[1])).to be false
    end

    it "does not resolve by step when there is no following note" do
      expect(guideline.send(:resolved_by_step?, counterpoint.notes.last)).to be false
    end
  end

  context "when a strong-beat note has no cantus firmus note at its position" do
    let(:guideline) { described_class.new(counterpoint) }

    before { counterpoint.place("12:1", :whole, "A4") }

    it "is not treated as a proper suspension" do
      note = counterpoint.notes.last
      expect(guideline.send(:properly_treated_suspension?, note)).to be false
    end
  end

  context "without a cantus firmus" do
    let(:bare_composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian", meter: "4/4") }
    let(:counterpoint) { bare_composition.add_voice(role: :counterpoint) }

    before { counterpoint.place("1:1", :whole, "A4") }

    it { is_expected.to be_adherent }

    it "produces no marks" do
      expect(described_class.new(counterpoint).marks).to eq([])
    end
  end
end
