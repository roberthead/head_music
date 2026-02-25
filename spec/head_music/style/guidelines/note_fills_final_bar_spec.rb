require "spec_helper"

describe HeadMusic::Style::Guidelines::NoteFillsFinalBar do
  subject { described_class.new(counterpoint) }

  let(:counterpoint) { composition.add_voice(role: :counterpoint) }

  before do
    composition.add_voice(role: :cantus_firmus).tap do |voice|
      cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", cf_rhythmic_value, pitch)
      end
    end
  end

  let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }

  context "in 4/4 meter" do
    let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
    let(:cf_rhythmic_value) { :whole }

    context "with a whole note in the final bar" do
      before do
        (1..10).each do |bar|
          counterpoint.place("#{bar}:1", :half, "A4")
          counterpoint.place("#{bar}:3", :half, "B4")
        end
        counterpoint.place("11:1", :whole, "D5")
      end

      it { is_expected.to be_adherent }
    end

    context "with a half note in the final bar" do
      before do
        (1..10).each do |bar|
          counterpoint.place("#{bar}:1", :half, "A4")
          counterpoint.place("#{bar}:3", :half, "B4")
        end
        counterpoint.place("11:1", :half, "D5")
      end

      its(:fitness) { is_expected.to be < 1 }
    end

    context "with two half notes in the final bar" do
      before do
        (1..10).each do |bar|
          counterpoint.place("#{bar}:1", :half, "A4")
          counterpoint.place("#{bar}:3", :half, "B4")
        end
        counterpoint.place("11:1", :half, "D5")
        counterpoint.place("11:3", :half, "E5")
      end

      its(:fitness) { is_expected.to be < 1 }
    end
  end

  context "in 3/4 meter" do
    let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian", meter: "3/4") }
    let(:cf_rhythmic_value) { :dotted_half }

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
end
