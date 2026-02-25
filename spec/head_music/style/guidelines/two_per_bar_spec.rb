require "spec_helper"

describe HeadMusic::Style::Guidelines::TwoPerBar do
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

  context "with two half notes in each middle bar" do
    before do
      # First bar: two half notes
      counterpoint.place("1:1", :half, "A4")
      counterpoint.place("1:3", :half, "G4")
      # Middle bars: two half notes each
      (2..10).each do |bar|
        counterpoint.place("#{bar}:1", :half, "A4")
        counterpoint.place("#{bar}:3", :half, "B4")
      end
      # Final bar: whole note
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a missing note in a middle bar" do
    before do
      counterpoint.place("1:1", :half, "A4")
      counterpoint.place("1:3", :half, "G4")
      counterpoint.place("2:1", :half, "A4")
      # bar 2 missing second half note
      counterpoint.place("3:1", :half, "C5")
      counterpoint.place("3:3", :half, "B4")
      (4..10).each do |bar|
        counterpoint.place("#{bar}:1", :half, "A4")
        counterpoint.place("#{bar}:3", :half, "B4")
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with whole notes instead of half notes in middle bars" do
    before do
      %w[A4 A4 C5 B4 D5 C5 E5 D5 A4 C#5 D5].each.with_index(1) do |pitch, bar|
        counterpoint.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with no notes" do
    its(:fitness) { is_expected.to be < 1 }
  end
end
