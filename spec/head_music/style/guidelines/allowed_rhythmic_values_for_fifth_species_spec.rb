require "spec_helper"

describe HeadMusic::Style::Guidelines::AllowedRhythmicValuesForFifthSpecies do
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

  context "with a mix of valid rhythmic values" do
    before do
      counterpoint.place("1:3", :half, "A4")
      counterpoint.place("2:1", :half, "A4")
      counterpoint.place("2:3", :half, "C5")
      counterpoint.place("3:1", :quarter, "B4")
      counterpoint.place("3:2", :eighth, "C5")
      counterpoint.place("3:2:480", :eighth, "B4")
      counterpoint.place("3:3", :quarter, "A4")
      counterpoint.place("3:4", :quarter, "G4")
      counterpoint.place("4:1", :whole, "A4")
    end

    it { is_expected.to be_adherent }
  end
end
