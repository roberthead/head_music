require "spec_helper"

describe HeadMusic::Style::Guidelines::NoStrongBeatUnisons do
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

  context "with no unisons on downbeats" do
    before do
      # All downbeats are thirds, fifths, sixths, or octaves — no unisons
      downbeat_pitches = %w[A4 A4 C5 A4 B4 A4 C5 B4 A4 C5 D5]
      downbeat_pitches.each_with_index do |pitch, index|
        bar = index + 1
        if bar == 11
          counterpoint.place("#{bar}:1", :whole, pitch)
        else
          counterpoint.place("#{bar}:1", :half, pitch)
          counterpoint.place("#{bar}:3", :half, "B4")
        end
      end
    end

    it { is_expected.to be_adherent }
  end

  context "with unisons at the first and last downbeats only" do
    before do
      # Bar 1: D4(P1/D4) — unison at beginning, allowed
      # Bar 11: D4(P1/D4) — unison at end, allowed
      # Middle bars: no unisons (careful to avoid A4 on bar 7 where CF=A4)
      counterpoint.place("1:1", :half, "D4")
      counterpoint.place("1:3", :half, "E4")
      # CF: D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4
      downbeat_pitches = %w[A4 C5 A4 B4 A4 C5 B4 A4 C5]
      downbeat_pitches.each_with_index do |pitch, index|
        bar = index + 2
        counterpoint.place("#{bar}:1", :half, pitch)
        counterpoint.place("#{bar}:3", :half, "B4")
      end
      counterpoint.place("11:1", :whole, "D4")
    end

    it { is_expected.to be_adherent }
  end

  context "with a unison on an interior downbeat" do
    before do
      # Bar 5: G4(P1/G4) — unison in middle, forbidden
      # No other accidental unisons (avoid A4 on bar 7 where CF=A4)
      counterpoint.place("1:1", :half, "A4")
      counterpoint.place("1:3", :half, "B4")
      (2..4).each do |bar|
        counterpoint.place("#{bar}:1", :half, "A4")
        counterpoint.place("#{bar}:3", :half, "B4")
      end
      counterpoint.place("5:1", :half, "G4") # unison with CF G4
      counterpoint.place("5:3", :half, "B4")
      counterpoint.place("6:1", :half, "A4")
      counterpoint.place("6:3", :half, "B4")
      counterpoint.place("7:1", :half, "C5") # avoid A4 unison with CF A4
      counterpoint.place("7:3", :half, "B4")
      (8..10).each do |bar|
        counterpoint.place("#{bar}:1", :half, "B4")
        counterpoint.place("#{bar}:3", :half, "C5")
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
  end
end
