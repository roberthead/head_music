require "spec_helper"

describe HeadMusic::Style::Guidelines::SuspensionTreatment do
  subject { described_class.new(counterpoint) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
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

  context "with all consonant sustained notes (no suspensions)" do
    before do
      # Each CP note is consonant with both its own bar CF and the next bar CF,
      # so no dissonant suspensions are created.
      %w[A4 C5 B4 D5 D5 C5 E5 D5 C5 B4].each_with_index do |pitch, index|
        counterpoint.place("#{index + 1}:3", :whole, pitch)
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a proper 7-6 suspension" do
    before do
      # Bar 2 CP = D5 (M6 with CF F4, consonant = preparation).
      # D5 sustains into bar 3 (CF=E4): m7 = dissonant suspension.
      # Bar 3 CP = C5 (m6 with CF E4, consonant = resolution by step down from D5).
      # C5 sustains into bar 4 (CF=D4): m7 = another dissonant suspension.
      # C5 was consonant with CF E4 at its start = prepared.
      # Bar 4 CP = B4 (M6 with CF D4, consonant = resolution by step down).
      # Both suspensions are properly prepared and resolved.
      %w[A4 D5 C5 B4 D5 C5 E5 D5 C5 B4].each_with_index do |pitch, index|
        counterpoint.place("#{index + 1}:3", :whole, pitch)
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a proper 4-3 suspension" do
    before do
      # Bar 9 CP = A4 (M3 with CF F4, consonant = preparation).
      # A4 sustains into bar 10 (CF=E4): P4 = dissonant suspension.
      # Bar 10 CP = B4 (P5 with CF E4, consonant = resolution by step up from A4).
      # B4 sustains into bar 11 (CF=D4): M6 = consonant (no further suspension).
      %w[A4 C5 B4 D5 D5 C5 E5 D5 A4 B4].each_with_index do |pitch, index|
        counterpoint.place("#{index + 1}:3", :whole, pitch)
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with an unresolved suspension that leaps instead of stepping" do
    before do
      # Bar 2 CP = D5 (M6 with CF F4, consonant = preparation).
      # D5 sustains into bar 3 (CF=E4): m7 = dissonant suspension.
      # Bar 3 CP = B4 (P5 with CF E4, consonant but m3 leap down from D5 = NOT a step).
      # Suspension is improperly resolved.
      %w[A4 D5 B4 D5 D5 C5 E5 D5 C5 B4].each_with_index do |pitch, index|
        counterpoint.place("#{index + 1}:3", :whole, pitch)
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
  end

  context "with an unprepared suspension" do
    let(:cantus_firmus_pitches) { %w[D4 F4 A4] }

    before do
      # Bar 1 CP = G4 (P4 with CF D4, dissonant = bad preparation).
      # G4 sustains into bar 2 (CF=F4): M2 = dissonant suspension.
      # Bar 2 CP = F4 (P1 with CF F4, consonant = resolution by step down from G4).
      # Suspension at bar 2 is improperly prepared (G4 was dissonant with previous CF D4).
      counterpoint.place("1:3", :whole, "G4")
      counterpoint.place("2:3", :whole, "F4")
      counterpoint.place("3:1", :whole, "E4")
    end

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
  end
end
