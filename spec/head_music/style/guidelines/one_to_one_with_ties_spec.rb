require "spec_helper"

describe HeadMusic::Style::Guidelines::OneToOneWithTies do
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

  context "with no counterpoint notes" do
    it { is_expected.not_to be_adherent }
  end

  context "with standard fourth species: notes start on weak beat and sustain across barlines" do
    before do
      # First bar: half rest then half note starting on beat 3
      counterpoint.place("1:3", :half, "A4")
      # Bars 2-10: half note on beat 3 sustains across barline into next bar
      (2..10).each do |bar|
        counterpoint.place("#{bar}:3", :half, %w[G4 A4 B4 A4 C5 B4 A4 G4 A4][bar - 2])
      end
      # Final bar: whole note
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a bar where no counterpoint note is sounding" do
    before do
      # Only place notes for a few bars, leaving a gap
      counterpoint.place("1:3", :half, "A4")
      # Skip bar 3 entirely — no note sounding at bar 3 beat 1
      counterpoint.place("4:3", :half, "B4")
      (5..10).each do |bar|
        counterpoint.place("#{bar}:3", :half, "A4")
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.not_to be_adherent }
  end

  context "with a second species break (two notes in a bar)" do
    before do
      counterpoint.place("1:3", :half, "A4")
      (2..9).each do |bar|
        counterpoint.place("#{bar}:3", :half, %w[G4 A4 B4 A4 C5 B4 A4 G4][bar - 2])
      end
      # Second species break in bar 10: two half notes
      counterpoint.place("10:1", :half, "G4")
      counterpoint.place("10:3", :half, "C#5")
      # Final bar: whole note
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end
end
