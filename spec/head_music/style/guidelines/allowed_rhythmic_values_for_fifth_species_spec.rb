require "spec_helper"

describe HeadMusic::Style::Guidelines::AllowedRhythmicValuesForFifthSpecies do
  subject(:annotation) { described_class.new(counterpoint) }

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

    it "has no final bar number" do
      # With an empty voice, last_note is nil, so both safe-navigation arms of
      # final_bar_number short-circuit to nil.
      expect(annotation.send(:final_bar_number)).to be_nil
    end
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

  context "with a lone eighth note that has no preceding or following note" do
    before do
      # A single eighth note is the only note in the voice, so it has neither
      # a preceding nor a following note. It is therefore unpaired and flagged.
      counterpoint.place("1:1", :eighth, "A4")
    end

    it { is_expected.not_to be_adherent }

    it "marks the unpaired eighth note" do
      expect(annotation.marks).not_to be_empty
    end
  end
end
