require "spec_helper"

describe HeadMusic::Style::Guidelines::FirstBarWholeNote do
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

  context "with a whole note in the first bar" do
    before do
      %w[A4 A4 C5 B4 D5 C5 E5 D5 A4 C#5 D5].each.with_index(1) do |pitch, bar|
        counterpoint.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
  end

  context "with two half notes in the first bar" do
    before do
      counterpoint.place("1:1", :half, "A4")
      counterpoint.place("1:3", :half, "G4")
      (2..11).each.with_index(2) do |_, bar|
        counterpoint.place("#{bar}:1", :whole, "A4")
      end
    end

    its(:fitness) { is_expected.to be < 1 }
  end
end
