require "spec_helper"

describe HeadMusic::Style::Guidelines::AllowedRhythmicValuesForCombined234 do
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

  context "with half notes only" do
    before do
      counterpoint.place("1:1", :half, "A4")
      counterpoint.place("1:3", :half, "B4")
      counterpoint.place("2:1", :half, "A4")
      counterpoint.place("2:3", :half, "C5")
      counterpoint.place("3:1", :half, "B4")
      counterpoint.place("3:3", :half, "A4")
      counterpoint.place("4:1", :half, "A4")
      counterpoint.place("4:3", :half, "A4")
    end

    it { is_expected.to be_adherent }
  end

  context "with a tied note starting on beat 3 (syncopation)" do
    before do
      counterpoint.place("1:3", :whole, "A4")
      counterpoint.place("2:3", :whole, "C5")
      counterpoint.place("3:3", :whole, "B4")
      counterpoint.place("4:1", :whole, "A4")
    end

    # Only bar 4 starts on beat 1 with a whole note
    its(:fitness) { is_expected.to be < 1 }
  end

  context "with a whole note on beat 1" do
    before do
      counterpoint.place("1:1", :whole, "A4")
      counterpoint.place("2:1", :half, "A4")
      counterpoint.place("2:3", :half, "C5")
      counterpoint.place("3:1", :half, "B4")
      counterpoint.place("3:3", :half, "A4")
      counterpoint.place("4:1", :half, "A4")
      counterpoint.place("4:3", :half, "A4")
    end

    its(:fitness) { is_expected.to be < 1 }
  end
end
