require "spec_helper"

describe HeadMusic::Style::Guidelines::FinalBarDottedHalfNote do
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

  context "with a dotted half note in the final bar" do
    before do
      (1..10).each do |bar|
        counterpoint.place("#{bar}:1", :quarter, "A4")
        counterpoint.place("#{bar}:2", :quarter, "B4")
        counterpoint.place("#{bar}:3", :quarter, "A4")
      end
      counterpoint.place("11:1", :dotted_half, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a quarter note in the final bar" do
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
