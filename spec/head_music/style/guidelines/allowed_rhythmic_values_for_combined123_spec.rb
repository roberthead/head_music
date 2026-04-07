require "spec_helper"

describe HeadMusic::Style::Guidelines::AllowedRhythmicValuesForCombined123 do
  subject { described_class.new(counterpoint) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian", meter: "4/4") }
  let(:counterpoint) { composition.add_voice(role: :counterpoint) }

  before do
    composition.add_voice(role: :cantus_firmus).tap do |voice|
      %w[D4 F4 E4 D4].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end
  end

  context "with no notes" do
    it { is_expected.to be_adherent }
  end

  context "with whole notes only" do
    before do
      counterpoint.place("1:1", :whole, "A4")
      counterpoint.place("2:1", :whole, "A4")
      counterpoint.place("3:1", :whole, "B4")
      counterpoint.place("4:1", :whole, "A4")
    end

    it { is_expected.to be_adherent }
  end

  context "with a mix of whole, half, and quarter notes" do
    before do
      counterpoint.place("1:1", :whole, "A4")
      counterpoint.place("2:1", :half, "A4")
      counterpoint.place("2:3", :half, "C5")
      counterpoint.place("3:1", :quarter, "B4")
      counterpoint.place("3:2", :quarter, "C5")
      counterpoint.place("3:3", :quarter, "B4")
      counterpoint.place("3:4", :quarter, "A4")
      counterpoint.place("4:1", :whole, "A4")
    end

    it { is_expected.to be_adherent }
  end

  context "with an eighth note" do
    before do
      counterpoint.place("1:1", :whole, "A4")
      counterpoint.place("2:1", :eighth, "A4")
      counterpoint.place("3:1", :whole, "B4")
      counterpoint.place("4:1", :whole, "A4")
    end

    its(:fitness) { is_expected.to be < 1 }
  end
end
