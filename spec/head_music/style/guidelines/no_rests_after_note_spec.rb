require "spec_helper"

describe HeadMusic::Style::Guidelines::NoRestsAfterNote do
  subject { described_class.new(counterpoint) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "C major", meter: "4/4") }
  let(:counterpoint) { composition.add_voice(role: :counterpoint) }

  before do
    composition.add_voice(role: :cantus_firmus).tap do |voice|
      %w[C4 D4 E4 F4 G4 F4 E4 D4 C4].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end
  end

  context "with no rests at all" do
    before do
      %w[E4 F4 G4 A4 B4 A4 G4 F4 E4].each.with_index(1) do |pitch, bar|
        counterpoint.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
  end

  context "with a leading rest before the first note" do
    before do
      counterpoint.place("1:1", :half, nil)
      counterpoint.place("1:3", :half, "E4")
      (2..8).each do |bar|
        counterpoint.place("#{bar}:1", :half, "G4")
        counterpoint.place("#{bar}:3", :half, "A4")
      end
      counterpoint.place("9:1", :whole, "C5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a rest after the first note" do
    before do
      counterpoint.place("1:1", :whole, "E4")
      counterpoint.place("2:1", :half, nil)
      counterpoint.place("2:3", :half, "F4")
      (3..9).each do |bar|
        counterpoint.place("#{bar}:1", :whole, %w[G4 A4 B4 A4 G4 F4 E4][bar - 3])
      end
    end

    it { is_expected.not_to be_adherent }
  end

  context "with a rest at the end" do
    before do
      (1..8).each do |bar|
        counterpoint.place("#{bar}:1", :whole, %w[E4 F4 G4 A4 B4 A4 G4 F4][bar - 1])
      end
      counterpoint.place("9:1", :half, "E4")
      counterpoint.place("9:3", :half, nil)
    end

    it { is_expected.not_to be_adherent }
  end

  context "with no notes and no rests" do
    it { is_expected.to be_adherent }
  end
end
