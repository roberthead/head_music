require "spec_helper"

describe HeadMusic::Style::Guidelines::FourPerBar do
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

  context "with four quarter notes in each middle bar" do
    before do
      (1..10).each do |bar|
        counterpoint.place("#{bar}:1", :quarter, "A4")
        counterpoint.place("#{bar}:2", :quarter, "B4")
        counterpoint.place("#{bar}:3", :quarter, "C5")
        counterpoint.place("#{bar}:4", :quarter, "B4")
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a missing note in a middle bar" do
    before do
      counterpoint.place("1:1", :quarter, "A4")
      counterpoint.place("1:2", :quarter, "G4")
      counterpoint.place("1:3", :quarter, "F4")
      counterpoint.place("1:4", :quarter, "G4")
      # Bar 2: only three quarter notes
      counterpoint.place("2:1", :quarter, "A4")
      counterpoint.place("2:2", :quarter, "B4")
      counterpoint.place("2:3", :quarter, "C5")
      (3..10).each do |bar|
        counterpoint.place("#{bar}:1", :quarter, "A4")
        counterpoint.place("#{bar}:2", :quarter, "B4")
        counterpoint.place("#{bar}:3", :quarter, "C5")
        counterpoint.place("#{bar}:4", :quarter, "B4")
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with half notes instead of quarter notes in middle bars" do
    before do
      (1..10).each do |bar|
        counterpoint.place("#{bar}:1", :half, "A4")
        counterpoint.place("#{bar}:3", :half, "B4")
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with no notes" do
    its(:fitness) { is_expected.to be < 1 }
  end
end
