require "spec_helper"

describe HeadMusic::Style::Guidelines::FirstBarQuarterNotes do
  subject { described_class.new(counterpoint) }

  context "in duple meter (4/4)" do
    let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
    let(:counterpoint) { composition.add_voice(role: :counterpoint) }

    before do
      composition.add_voice(role: :cantus_firmus).tap do |voice|
        %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end
    end

    context "with four quarter notes in the first bar" do
      before do
        counterpoint.place("1:1", :quarter, "A4")
        counterpoint.place("1:2", :quarter, "G4")
        counterpoint.place("1:3", :quarter, "F4")
        counterpoint.place("1:4", :quarter, "G4")
        (2..10).each do |bar|
          counterpoint.place("#{bar}:1", :quarter, "A4")
          counterpoint.place("#{bar}:2", :quarter, "B4")
          counterpoint.place("#{bar}:3", :quarter, "C5")
          counterpoint.place("#{bar}:4", :quarter, "B4")
        end
        counterpoint.place("11:1", :whole, "D5")
      end

      it { is_expected.to be_adherent }
    end

    context "with a quarter rest on beat 1 of the first bar" do
      before do
        counterpoint.place("1:1", :quarter)
        counterpoint.place("1:2", :quarter, "A4")
        counterpoint.place("1:3", :quarter, "G4")
        counterpoint.place("1:4", :quarter, "F4")
        (2..10).each do |bar|
          counterpoint.place("#{bar}:1", :quarter, "A4")
          counterpoint.place("#{bar}:2", :quarter, "B4")
          counterpoint.place("#{bar}:3", :quarter, "C5")
          counterpoint.place("#{bar}:4", :quarter, "B4")
        end
        counterpoint.place("11:1", :whole, "D5")
      end

      it { is_expected.to be_adherent }
    end

    context "with three quarter notes after beat 1 in the first bar" do
      before do
        counterpoint.place("1:2", :quarter, "A4")
        counterpoint.place("1:3", :quarter, "G4")
        counterpoint.place("1:4", :quarter, "F4")
        (2..10).each do |bar|
          counterpoint.place("#{bar}:1", :quarter, "A4")
          counterpoint.place("#{bar}:2", :quarter, "B4")
          counterpoint.place("#{bar}:3", :quarter, "C5")
          counterpoint.place("#{bar}:4", :quarter, "B4")
        end
        counterpoint.place("11:1", :whole, "D5")
      end

      it { is_expected.to be_adherent }
    end

    context "with only a quarter rest in the first bar and no notes" do
      before do
        counterpoint.place("1:1", :quarter)
        (2..10).each do |bar|
          counterpoint.place("#{bar}:1", :quarter, "A4")
          counterpoint.place("#{bar}:2", :quarter, "B4")
          counterpoint.place("#{bar}:3", :quarter, "C5")
          counterpoint.place("#{bar}:4", :quarter, "B4")
        end
        counterpoint.place("11:1", :whole, "D5")
      end

      its(:fitness) { is_expected.to be < 1 }
    end
  end

  context "in triple meter (3/4)" do
    let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian", meter: "3/4") }
    let(:counterpoint) { composition.add_voice(role: :counterpoint) }

    before do
      composition.add_voice(role: :cantus_firmus).tap do |voice|
        %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :dotted_half, pitch)
        end
      end
    end

    context "with three quarter notes in the first bar" do
      before do
        counterpoint.place("1:1", :quarter, "A4")
        counterpoint.place("1:2", :quarter, "G4")
        counterpoint.place("1:3", :quarter, "A4")
        (2..10).each do |bar|
          counterpoint.place("#{bar}:1", :quarter, "A4")
          counterpoint.place("#{bar}:2", :quarter, "B4")
          counterpoint.place("#{bar}:3", :quarter, "A4")
        end
        counterpoint.place("11:1", :dotted_half, "D5")
      end

      it { is_expected.to be_adherent }
    end

    context "with a quarter rest on beat 1 of the first bar" do
      before do
        counterpoint.place("1:1", :quarter)
        counterpoint.place("1:2", :quarter, "G4")
        counterpoint.place("1:3", :quarter, "A4")
        (2..10).each do |bar|
          counterpoint.place("#{bar}:1", :quarter, "A4")
          counterpoint.place("#{bar}:2", :quarter, "B4")
          counterpoint.place("#{bar}:3", :quarter, "A4")
        end
        counterpoint.place("11:1", :dotted_half, "D5")
      end

      it { is_expected.to be_adherent }
    end

    context "with two quarter notes after beat 1 in the first bar" do
      before do
        counterpoint.place("1:2", :quarter, "G4")
        counterpoint.place("1:3", :quarter, "A4")
        (2..10).each do |bar|
          counterpoint.place("#{bar}:1", :quarter, "A4")
          counterpoint.place("#{bar}:2", :quarter, "B4")
          counterpoint.place("#{bar}:3", :quarter, "A4")
        end
        counterpoint.place("11:1", :dotted_half, "D5")
      end

      it { is_expected.to be_adherent }
    end

    context "with only one quarter note on beat 3 of the first bar (two implicit rests)" do
      before do
        counterpoint.place("1:3", :quarter, "A4")
        (2..10).each do |bar|
          counterpoint.place("#{bar}:1", :quarter, "A4")
          counterpoint.place("#{bar}:2", :quarter, "B4")
          counterpoint.place("#{bar}:3", :quarter, "A4")
        end
        counterpoint.place("11:1", :dotted_half, "D5")
      end

      its(:fitness) { is_expected.to be < 1 }
    end
  end
end
