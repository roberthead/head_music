require "spec_helper"

describe HeadMusic::Style::Guidelines::TwoToOne do
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

  context "with a well-formed second-species counterpoint" do
    before do
      # Two half notes per bar, whole note in the final bar
      counterpoint_notes = %w[A4 G4 A4 C5 C5 B4 A4 B4 D5 C5 C5 A4 E5 D5 D5 B4 A4 C5 C#5 D5]
      counterpoint_notes.each_with_index do |pitch, index|
        bar = index / 2 + 1
        beat = (index % 2) * 2 + 1
        counterpoint.place("#{bar}:#{beat}", :half, pitch)
      end
      # Final bar: whole note
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a half rest on beat 1 of the first bar" do
    before do
      # First bar: half rest + half note
      counterpoint.place("1:1", :half)
      counterpoint.place("1:3", :half, "A4")
      # Middle bars: two half notes each
      middle_notes = %w[A4 C5 C5 B4 A4 B4 D5 C5 C5 A4 E5 D5 D5 B4 A4 C5 C#5]
      middle_notes.each_with_index do |pitch, index|
        bar = index / 2 + 2
        beat = (index % 2) * 2 + 1
        counterpoint.place("#{bar}:#{beat}", :half, pitch)
      end
      counterpoint.place("10:3", :half, "C#5")
      # Final bar: whole note
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a single half note after beat 1 in the first bar (no explicit rest)" do
    before do
      # First bar: only a half note on beat 3, no rest placed
      counterpoint.place("1:3", :half, "A4")
      # Middle bars: two half notes each
      middle_notes = %w[A4 C5 C5 B4 A4 B4 D5 C5 C5 A4 E5 D5 D5 B4 A4 C5 C#5]
      middle_notes.each_with_index do |pitch, index|
        bar = index / 2 + 2
        beat = (index % 2) * 2 + 1
        counterpoint.place("#{bar}:#{beat}", :half, pitch)
      end
      counterpoint.place("10:3", :half, "C#5")
      # Final bar: whole note
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with only a half rest in the first bar and no note" do
    before do
      # First bar: half rest only, no note
      counterpoint.place("1:1", :half)
      # Remaining bars: two half notes each
      (2..10).each do |bar|
        counterpoint.place("#{bar}:1", :half, "A4")
        counterpoint.place("#{bar}:3", :half, "B4")
      end
      # Final bar: whole note
      counterpoint.place("11:1", :whole, "D5")
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with whole notes instead of half notes" do
    before do
      %w[A4 A4 C5 B4 D5 C5 E5 D5 A4 C#5 D5].each.with_index(1) do |pitch, bar|
        counterpoint.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with a missing note in a middle bar" do
    before do
      # Only one half note in bar 2 instead of two
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

  context "with a half note in the final bar instead of a whole note" do
    before do
      (1..10).each do |bar|
        counterpoint.place("#{bar}:1", :half, "A4")
        counterpoint.place("#{bar}:3", :half, "B4")
      end
      counterpoint.place("11:1", :half, "D5")
    end

    its(:fitness) { is_expected.to be < 1 }
  end
end
