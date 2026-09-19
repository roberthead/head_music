require "spec_helper"

describe HeadMusic::Style::Guidelines::SustainAcrossBarlines do
  subject(:guideline) { assess(described_class, counterpoint) }

  let(:flow) { HeadMusic::Content::Flow.new(key_signature: "D dorian") }
  let(:counterpoint) { flow.add_voice(role: :counterpoint) }

  def place_whole_notes(voice, pitches)
    pitches.each.with_index(1) { |pitch, bar| voice.place("#{bar}:1", :whole, pitch) }
  end

  context "with a first-species line and no cantus firmus" do
    before { place_whole_notes(counterpoint, %w[A4 A4 G4 A4 B4 C5 C5 B4 D5 C#5 D5]) }

    it "is judged over the voice's own bars" do
      expect(guideline.marks_count).to eq 9
    end
  end

  context "with a cantus firmus" do
    before do
      flow.add_voice(role: :cantus_firmus).tap do |voice|
        place_whole_notes(voice, %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4])
      end
    end

    context "with no counterpoint notes" do
      it { is_expected.to be_adherent }

      it "returns no marks" do
        expect(guideline.marks).to be_empty
      end
    end

    context "with Fux's fourth-species line" do
      let(:counterpoint) { fux_fourth_species_examples.first.counterpoint_voice }

      it { is_expected.to be_adherent }
    end

    context "with whole notes placed on beat three" do
      before do
        %w[A4 D5 C5 B4 D5 C5 E5 D5 C5].each_with_index do |pitch, index|
          counterpoint.place("#{index + 1}:3", :whole, pitch)
        end
        counterpoint.place("10:3", :half, "C#5")
        counterpoint.place("11:1", :whole, "D5")
      end

      it { is_expected.to be_adherent }
    end

    context "with half notes tied across each barline" do
      before do
        counterpoint.place("1:3", "half tied to half", "A4")
        %w[D5 C5 B4 D5 C5 E5 D5 C5].each_with_index do |pitch, index|
          counterpoint.place("#{index + 2}:3", "half tied to half", pitch)
        end
        counterpoint.place("10:3", :half, "C#5")
        counterpoint.place("11:1", :whole, "D5")
      end

      it { is_expected.to be_adherent }
    end

    context "with a first-species line" do
      before { place_whole_notes(counterpoint, %w[A4 A4 G4 A4 B4 C5 C5 B4 D5 C#5 D5]) }

      it { is_expected.not_to be_adherent }

      it "marks every middle bar once the breaks exceed the allowance" do
        expect(guideline.marks_count).to eq 9
      end

      it "scores each break at the penalty factor" do
        expect(guideline.fitness).to be_within(0.001).of(HeadMusic::PENALTY_FACTOR**9)
      end
    end

    context "with untied halves re-attacked on each downbeat" do
      before do
        counterpoint.place("1:3", :half, "A4")
        %w[A4 D5 D5 C5 C5 B4 B4 D5 D5 C5 C5 E5 E5 D5 D5 C5 C5 C#5].each_with_index do |pitch, index|
          bar = index / 2 + 2
          beat = index.even? ? 1 : 3
          counterpoint.place("#{bar}:#{beat}", :half, pitch)
        end
        counterpoint.place("11:1", :whole, "D5")
      end

      it "counts each re-attack as a break" do
        expect(guideline.marks_count).to eq 9
      end
    end

    context "with occasional breaks in the syncopation" do
      let(:pitches) { %w[A4 D5 C5 B4 D5 C5 E5 D5 C5] }

      before do
        counterpoint.place("1:3", "half tied to half", "A4")
        pitches.drop(1).each_with_index do |pitch, index|
          bar = index + 2
          if break_bars.include?(bar)
            counterpoint.place("#{bar}:3", :half, pitch)
          else
            counterpoint.place("#{bar}:3", "half tied to half", pitch)
          end
        end
        counterpoint.place("10:3", :half, "C#5")
        counterpoint.place("11:1", :whole, "D5")
      end

      context "with breaks within the tolerated ratio" do
        let(:break_bars) { [4, 7] }

        it { is_expected.to be_adherent }
      end

      context "with breaks beyond the tolerated ratio" do
        let(:break_bars) { [3, 5, 7] }

        it "marks every bar entered without a ligature, not only those past the allowance" do
          expect(guideline.marks_count).to eq 3
          expect(guideline.marks_array.map(&:code)).to eq ["4:3:000 to 5:3:000", "6:3:000 to 7:3:000", "8:3:000 to 9:3:000"]
        end
      end

      context "with no tolerance configured" do
        subject(:guideline) { assess(described_class, counterpoint, max_break_ratio: 0) }

        let(:break_bars) { [5] }

        it "marks the one break" do
          expect(guideline.marks_count).to eq 1
        end
      end
    end

    context "with a bar left empty inside the line" do
      subject(:guideline) { assess(described_class, counterpoint, max_break_ratio: 0) }

      before do
        counterpoint.place("1:3", "half tied to half", "A4")
        counterpoint.place("2:3", "half tied to half", "D5")
        counterpoint.place("3:3", "half tied to half", "C5")
        counterpoint.place("4:3", :half, "B4")
        counterpoint.place("6:1", :whole, "D5")
        counterpoint.place("7:1", :whole, "D5")
      end

      it "marks the empty bar without raising" do
        expect(guideline.marks_count).to eq 2
        expect(guideline.marks_array.map(&:code)).to include("5:1:000 to 6:1:000")
      end
    end

    context "with a two-bar voice" do
      before do
        counterpoint.place("1:3", "half tied to half", "A4")
        counterpoint.place("2:3", :half, "D5")
      end

      it { is_expected.to be_adherent }
    end
  end
end
