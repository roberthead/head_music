require "spec_helper"

describe HeadMusic::Style::Guidelines::FourToOne do
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
    its(:fitness) { is_expected.to be < 1 }
  end

  context "with a well-formed third-species counterpoint" do
    before do
      # Four quarter notes per bar, whole note in the final bar
      counterpoint_notes = %w[
        A4 G4 F4 G4
        A4 B4 C5 B4
        C5 B4 A4 G4
        A4 B4 C5 D5
        D5 C5 B4 A4
        A4 C5 B4 A4
        E5 D5 C5 B4
        D5 C5 B4 A4
        A4 B4 C5 D5
        C#5 D5 E5 C#5
      ]
      counterpoint_notes.each_with_index do |pitch, index|
        bar = index / 4 + 1
        beat = (index % 4) + 1
        counterpoint.place("#{bar}:#{beat}", :quarter, pitch)
      end
      # Final bar: whole note
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a quarter rest on beat 1 of the first bar" do
    before do
      # First bar: quarter rest + three quarter notes
      counterpoint.place("1:1", :quarter)
      counterpoint.place("1:2", :quarter, "A4")
      counterpoint.place("1:3", :quarter, "G4")
      counterpoint.place("1:4", :quarter, "F4")
      # Middle bars: four quarter notes each
      (2..10).each do |bar|
        counterpoint.place("#{bar}:1", :quarter, "A4")
        counterpoint.place("#{bar}:2", :quarter, "B4")
        counterpoint.place("#{bar}:3", :quarter, "C5")
        counterpoint.place("#{bar}:4", :quarter, "B4")
      end
      # Final bar: whole note
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with three quarter notes after beat 1 in the first bar (no explicit rest)" do
    before do
      # First bar: only three quarter notes starting on beat 2
      counterpoint.place("1:2", :quarter, "A4")
      counterpoint.place("1:3", :quarter, "G4")
      counterpoint.place("1:4", :quarter, "F4")
      # Middle bars: four quarter notes each
      (2..10).each do |bar|
        counterpoint.place("#{bar}:1", :quarter, "A4")
        counterpoint.place("#{bar}:2", :quarter, "B4")
        counterpoint.place("#{bar}:3", :quarter, "C5")
        counterpoint.place("#{bar}:4", :quarter, "B4")
      end
      # Final bar: whole note
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with only a quarter rest in the first bar and no notes" do
    before do
      # First bar: quarter rest only, no notes
      counterpoint.place("1:1", :quarter)
      # Remaining bars: four quarter notes each
      (2..10).each do |bar|
        counterpoint.place("#{bar}:1", :quarter, "A4")
        counterpoint.place("#{bar}:2", :quarter, "B4")
        counterpoint.place("#{bar}:3", :quarter, "C5")
        counterpoint.place("#{bar}:4", :quarter, "B4")
      end
      # Final bar: whole note
      counterpoint.place("11:1", :whole, "D5")
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with whole notes instead of quarter notes" do
    before do
      %w[A4 A4 C5 B4 D5 C5 E5 D5 A4 C#5 D5].each.with_index(1) do |pitch, bar|
        counterpoint.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with half notes instead of quarter notes" do
    before do
      (1..10).each do |bar|
        counterpoint.place("#{bar}:1", :half, "A4")
        counterpoint.place("#{bar}:3", :half, "B4")
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with a missing note in a middle bar" do
    before do
      # First bar: four quarter notes
      counterpoint.place("1:1", :quarter, "A4")
      counterpoint.place("1:2", :quarter, "G4")
      counterpoint.place("1:3", :quarter, "F4")
      counterpoint.place("1:4", :quarter, "G4")
      # Bar 2: only three quarter notes (missing one)
      counterpoint.place("2:1", :quarter, "A4")
      counterpoint.place("2:2", :quarter, "B4")
      counterpoint.place("2:3", :quarter, "C5")
      # Bars 3-10: four quarter notes each
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

  context "with a quarter note in the final bar instead of a whole note" do
    before do
      (1..10).each do |bar|
        counterpoint.place("#{bar}:1", :quarter, "A4")
        counterpoint.place("#{bar}:2", :quarter, "B4")
        counterpoint.place("#{bar}:3", :quarter, "C5")
        counterpoint.place("#{bar}:4", :quarter, "B4")
      end
      counterpoint.place("11:1", :quarter, "D5")
    end

    its(:fitness) { is_expected.to be < 1 }
  end
end
