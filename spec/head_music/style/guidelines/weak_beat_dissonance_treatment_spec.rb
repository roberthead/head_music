require "spec_helper"

describe HeadMusic::Style::Guidelines::WeakBeatDissonanceTreatment do
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

  context "with all consonant weak beats" do
    before do
      # All intervals are consonant with the cantus firmus
      # Bar 1: A4(P5/D4) B4(M6/D4) — both consonant
      # Bar 2: A4(M3/F4) C5(P5/F4) — both consonant
      # Bar 3: B4(P5/E4) C5(m6/E4) — both consonant
      # Bar 4: A4(P5/D4) B4(M6/D4) — both consonant
      # Bar 5: D5(P5/G4) E5(M6/G4) — both consonant
      # Bar 6: A4(M3/F4) C5(P5/F4) — both consonant
      # Bar 7: E5(P5/A4) C5(m3/A4) — both consonant
      # Bar 8: D5(P5/G4) E5(M6/G4) — both consonant
      # Bar 9: A4(M3/F4) C5(P5/F4) — both consonant
      # Bar 10: B4(P5/E4) C5(m6/E4) — both consonant
      # Bar 11: D5(P8/D4) — whole note
      half_notes = %w[A4 B4 A4 C5 B4 C5 A4 B4 D5 E5 A4 C5 E5 C5 D5 E5 A4 C5 B4 C5]
      half_notes.each_with_index do |pitch, index|
        bar = index / 2 + 1
        beat = (index % 2) * 2 + 1
        counterpoint.place("#{bar}:#{beat}", :half, pitch)
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a valid passing tone on the weak beat" do
    before do
      # Bar 1: B4(M6/D4) C5(m7/D4=dissonant) — ascending passing tone B4→C5→D5
      # Bar 2: D5(M6/F4) C5(P5/F4) — both consonant
      # Bars 3-10: all consonant
      # Bar 11: D5 whole note
      half_notes = %w[B4 C5 D5 C5 B4 C5 A4 B4 D5 E5 A4 C5 E5 C5 D5 E5 A4 C5 B4 C5]
      half_notes.each_with_index do |pitch, index|
        bar = index / 2 + 1
        beat = (index % 2) * 2 + 1
        counterpoint.place("#{bar}:#{beat}", :half, pitch)
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a dissonant neighbor tone on the weak beat" do
    before do
      # Bar 1: A4(P5/D4) G4(P4/D4=dissonant) — G4 is approached by step down
      #   but left by step UP (A4→G4→A4), making it a neighbor tone, not a passing tone
      # Bar 2: A4(M3/F4) C5(P5/F4) — both consonant
      # Bars 3-10: all consonant
      # Bar 11: D5 whole note
      half_notes = %w[A4 G4 A4 C5 B4 C5 A4 B4 D5 E5 A4 C5 E5 C5 D5 E5 A4 C5 B4 C5]
      half_notes.each_with_index do |pitch, index|
        bar = index / 2 + 1
        beat = (index % 2) * 2 + 1
        counterpoint.place("#{bar}:#{beat}", :half, pitch)
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
  end

  context "with a dissonant weak-beat note approached by leap" do
    before do
      # Bar 1: D5(P8/D4) G4(P4/D4=dissonant) — leap from D5 to G4, not stepwise approach
      half_notes = %w[D5 G4 A4 C5 B4 C5 A4 B4 D5 E5 A4 C5 E5 C5 D5 E5 A4 C5 B4 C5]
      half_notes.each_with_index do |pitch, index|
        bar = index / 2 + 1
        beat = (index % 2) * 2 + 1
        counterpoint.place("#{bar}:#{beat}", :half, pitch)
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
  end
end
