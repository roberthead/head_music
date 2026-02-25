require "spec_helper"

describe HeadMusic::Style::Guidelines::FirstBarHalfNotes do
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

  context "with two half notes in the first bar" do
    before do
      counterpoint.place("1:1", :half, "A4")
      counterpoint.place("1:3", :half, "G4")
      (2..10).each do |bar|
        counterpoint.place("#{bar}:1", :half, "A4")
        counterpoint.place("#{bar}:3", :half, "B4")
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a half rest on beat 1 of the first bar" do
    before do
      counterpoint.place("1:1", :half)
      counterpoint.place("1:3", :half, "A4")
      (2..10).each do |bar|
        counterpoint.place("#{bar}:1", :half, "A4")
        counterpoint.place("#{bar}:3", :half, "B4")
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a single half note after beat 1 in the first bar" do
    before do
      counterpoint.place("1:3", :half, "A4")
      (2..10).each do |bar|
        counterpoint.place("#{bar}:1", :half, "A4")
        counterpoint.place("#{bar}:3", :half, "B4")
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with only a half rest in the first bar and no note" do
    before do
      counterpoint.place("1:1", :half)
      (2..10).each do |bar|
        counterpoint.place("#{bar}:1", :half, "A4")
        counterpoint.place("#{bar}:3", :half, "B4")
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with a whole note in the first bar" do
    before do
      counterpoint.place("1:1", :whole, "A4")
      (2..10).each do |bar|
        counterpoint.place("#{bar}:1", :half, "A4")
        counterpoint.place("#{bar}:3", :half, "B4")
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    its(:fitness) { is_expected.to be < 1 }
  end
end
