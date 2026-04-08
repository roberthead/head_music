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
end
