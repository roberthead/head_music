require "spec_helper"

describe HeadMusic::Style::Guidelines::ThreeToOne do
  subject { described_class.new(counterpoint) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian", meter: "3/4") }
  let(:counterpoint) { composition.add_voice(role: :counterpoint) }
  let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }

  before do
    composition.add_voice(role: :cantus_firmus).tap do |voice|
      cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :dotted_half, pitch)
      end
    end
  end

  context "with no notes" do
    its(:fitness) { is_expected.to be < 1 }
  end

  context "with a well-formed triple-meter counterpoint" do
    before do
      # Three quarter notes per bar, dotted half in the final bar
      counterpoint_notes = %w[A4 G4 A4 A4 C5 B4 C5 B4 A4 A4 B4 C5 D5 C5 B4 C5 A4 C5 E5 D5 C5 D5 B4 A4 A4 C5 B4 C#5 D5 C#5]
      counterpoint_notes.each_with_index do |pitch, index|
        bar = index / 3 + 1
        beat = index % 3 + 1
        counterpoint.place("#{bar}:#{beat}", :quarter, pitch)
      end
      # Final bar: dotted half note
      counterpoint.place("11:1", :dotted_half, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a quarter rest on beat 1 of the first bar" do
    before do
      # First bar: quarter rest + two quarter notes
      counterpoint.place("1:1", :quarter)
      counterpoint.place("1:2", :quarter, "G4")
      counterpoint.place("1:3", :quarter, "A4")
      # Middle bars: three quarter notes each
      (2..10).each do |bar|
        counterpoint.place("#{bar}:1", :quarter, "A4")
        counterpoint.place("#{bar}:2", :quarter, "B4")
        counterpoint.place("#{bar}:3", :quarter, "A4")
      end
      # Final bar: dotted half note
      counterpoint.place("11:1", :dotted_half, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with two quarter notes after beat 1 in the first bar (no explicit rest)" do
    before do
      # First bar: only quarter notes on beats 2 and 3
      counterpoint.place("1:2", :quarter, "G4")
      counterpoint.place("1:3", :quarter, "A4")
      # Middle bars: three quarter notes each
      (2..10).each do |bar|
        counterpoint.place("#{bar}:1", :quarter, "A4")
        counterpoint.place("#{bar}:2", :quarter, "B4")
        counterpoint.place("#{bar}:3", :quarter, "A4")
      end
      # Final bar: dotted half note
      counterpoint.place("11:1", :dotted_half, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with only two quarter notes in a middle bar" do
    before do
      # First bar: three quarter notes
      counterpoint.place("1:1", :quarter, "A4")
      counterpoint.place("1:2", :quarter, "G4")
      counterpoint.place("1:3", :quarter, "A4")
      # Bar 2: only two quarter notes (violation)
      counterpoint.place("2:1", :quarter, "A4")
      counterpoint.place("2:2", :quarter, "C5")
      # Bars 3-10: three quarter notes each
      (3..10).each do |bar|
        counterpoint.place("#{bar}:1", :quarter, "A4")
        counterpoint.place("#{bar}:2", :quarter, "B4")
        counterpoint.place("#{bar}:3", :quarter, "A4")
      end
      # Final bar: dotted half note
      counterpoint.place("11:1", :dotted_half, "D5")
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with a quarter note in the final bar instead of a dotted half" do
    before do
      (1..10).each do |bar|
        counterpoint.place("#{bar}:1", :quarter, "A4")
        counterpoint.place("#{bar}:2", :quarter, "B4")
        counterpoint.place("#{bar}:3", :quarter, "A4")
      end
      counterpoint.place("11:1", :quarter, "D5")
    end

    its(:fitness) { is_expected.to be < 1 }
  end
end
