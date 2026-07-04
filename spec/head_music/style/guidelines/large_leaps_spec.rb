require "spec_helper"

describe HeadMusic::Style::Guidelines::LargeLeaps do
  subject(:guideline) { described_class.new(voice, **options) }

  let(:options) { {} }
  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
  let(:voice) { HeadMusic::Content::Voice.new(composition: composition) }

  def place_pitches(pitches)
    pitches.each.with_index(1) do |pitch, bar|
      voice.place("#{bar}:1", :whole, pitch)
    end
  end

  describe "#message" do
    it "returns the default message" do
      expect(guideline.message).to eq "Recover leaps by step, repetition, opposite direction, or spelling triad."
    end

    context "with a message option" do
      let(:options) { {message: "Custom leap guidance."} }

      its(:message) { is_expected.to eq "Custom leap guidance." }
    end
  end

  context "with no notes" do
    it { is_expected.to be_adherent }
  end

  context "with fewer than three note pairs" do
    before { place_pitches %w[D4 G4 D4] }

    it { is_expected.to be_adherent }
    its(:marks_count) { is_expected.to eq 0 }
  end

  describe "minimum threshold" do
    context "with an ascending fourth continued by a same-direction step" do
      before { place_pitches %w[D4 F4 E4 D4 G4 A4 G4 F4 E4 D4] }

      context "when the minimum is a perfect fourth" do
        let(:options) { {minimum: :perfect_fourth, recovery: %i[consonant_triad opposite_step]} }

        its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
      end

      context "when the minimum is a perfect fifth" do
        let(:options) { {minimum: :perfect_fifth, recovery: %i[consonant_triad opposite_step]} }

        it { is_expected.to be_adherent }
      end

      context "when the minimum is a DiatonicInterval object for a perfect fourth" do
        let(:options) do
          {
            minimum: HeadMusic::Analysis::DiatonicInterval.get(:perfect_fourth),
            recovery: %i[consonant_triad opposite_step]
          }
        end

        its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
      end

      context "when the minimum is a DiatonicInterval object for a perfect fifth" do
        let(:options) do
          {
            minimum: HeadMusic::Analysis::DiatonicInterval.get(:perfect_fifth),
            recovery: %i[consonant_triad opposite_step]
          }
        end

        it { is_expected.to be_adherent }
      end
    end

    context "with an unrecovered ascending augmented fourth (six semitones)" do
      before { place_pitches %w[D4 E4 F4 B4 C5 B4 A4 G4 F4 E4 D4] }

      context "when the minimum is a perfect fourth" do
        let(:options) { {minimum: :perfect_fourth, recovery: %i[consonant_triad opposite_step]} }

        its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
      end

      context "when the minimum is a perfect fifth" do
        let(:options) { {minimum: :perfect_fifth, recovery: %i[consonant_triad opposite_step]} }

        it "compares by diatonic number, not semitones" do
          expect(guideline).to be_adherent
        end
      end
    end
  end

  describe "recovery modes" do
    context "with a large leap answered by a note repetition" do
      before { place_pitches %w[D4 F4 E4 D4 G4 G4 F4 E4 D4] }

      context "when recovery includes repetition" do
        let(:options) { {recovery: %i[repetition]} }

        it { is_expected.to be_adherent }
      end

      context "when recovery is opposite step only" do
        let(:options) { {recovery: %i[opposite_step]} }

        its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
      end
    end

    context "with a large leap answered by an equal opposite leap" do
      let(:options) { {recovery: %i[opposite_leap_within any_step]} }

      before { place_pitches %w[D4 G4 D4 E4 F4 E4 D4] }

      it { is_expected.to be_adherent }
    end

    context "with a large leap answered by a smaller opposite leap" do
      let(:options) { {recovery: %i[opposite_leap_within any_step]} }

      before { place_pitches %w[D4 G4 E4 F4 E4 D4] }

      it { is_expected.to be_adherent }
    end

    context "with a large leap answered by a larger opposite leap" do
      before { place_pitches %w[D4 G4 C4 D4 E4 F4 E4 D4] }

      context "when recovery uses the bounded opposite leap" do
        let(:options) { {recovery: %i[opposite_leap_within any_step]} }

        its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
      end

      context "when recovery uses the unbounded opposite leap" do
        let(:options) { {recovery: %i[opposite_leap any_step]} }

        it { is_expected.to be_adherent }
      end
    end
  end

  describe "independent ascending and descending thresholds" do
    context "with a Fux-like configuration forbidding descending sixths" do
      let(:options) do
        {
          minimum: :perfect_fourth,
          descending: {minimum: :perfect_fourth, forbidden: :minor_sixth},
          recovery: %i[consonant_triad opposite_step]
        }
      end

      context "with an ascending minor sixth recovered by a step in the opposite direction" do
        before { place_pitches %w[D4 E4 C5 B4 A4 G4 F4 E4 D4] }

        it { is_expected.to be_adherent }
      end

      context "with a descending minor sixth recovered by a step in the opposite direction" do
        before { place_pitches %w[A4 B4 C5 E4 F4 G4 A4] }

        its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
      end

      context "with a descending perfect fifth recovered by a step in the opposite direction" do
        before { place_pitches %w[A4 B4 C5 F4 G4 F4 E4 D4] }

        it { is_expected.to be_adherent }
      end
    end

    context "with an unrecovered descending fourth" do
      before { place_pitches %w[A4 B4 C5 G4 F4 E4 D4 E4 F4] }

      context "when the descending option is a bare interval shorthand for the minimum" do
        let(:options) { {descending: :perfect_fifth, recovery: %i[opposite_step]} }

        it { is_expected.to be_adherent }
      end

      context "when the descending direction falls back to the top-level minimum" do
        let(:options) { {recovery: %i[opposite_step]} }

        its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
      end
    end
  end

  describe "maximum consecutive leaps" do
    let(:options) { {maximum_consecutive_leaps: 2} }

    context "with three qualifying leaps in a row" do
      before { place_pitches %w[D4 G4 D4 G4 F4 E4 D4] }

      its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
      its(:marks_count) { is_expected.to eq 1 }
    end

    context "with two qualifying leaps in a row" do
      before { place_pitches %w[D4 G4 D4 E4 F4 E4 D4] }

      it { is_expected.to be_adherent }
    end

    context "with a run of leaps broken by a step" do
      before { place_pitches %w[D4 G4 A4 E4 D4 E4 F4 E4 D4] }

      it { is_expected.to be_adherent }
    end
  end

  describe "as a drop-in replacement for RecoverLargeLeaps" do
    let(:options) { {recovery: %i[consonant_triad opposite_step]} }

    context "with no notes" do
      it { is_expected.to be_adherent }
    end

    context "with leaps" do
      context "when recovered by step in the opposite direction" do
        before { place_pitches %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }

        it { is_expected.to be_adherent }
      end

      context "when recovered by skip in the opposite direction" do
        before { place_pitches %w[D4 F4 E4 D4 G4 E4 A4 G4 F4 E4 D4] }

        its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
        its(:first_mark_code) { is_expected.to eq "4:1:000 to 7:1:000" }
      end

      context "when not recovered, not spelling a triad" do
        before { place_pitches %w[D4 F4 E4 D4 G4 A4 G4 F4 E4 D4] }

        its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
        its(:first_mark_code) { is_expected.to eq "4:1:000 to 7:1:000" }
      end

      context "when not recovered, but spelling a triad" do
        before { place_pitches %w[D4 F4 E4 D4 G4 B4 G4 F4 E4 D4] }

        it { is_expected.to be_adherent }
      end

      context "when the leap is recovered by skip spelling a triad" do
        let(:composition) { HeadMusic::Content::Composition.new(key_signature: "F lydian") }

        before do
          # FUX example
          place_pitches %w[F4 G4 A4 F4 D4 E4 F4 C5 A4 F4 G4 F4]
        end

        it { is_expected.to be_adherent }
        its(:first_mark_code) { is_expected.to be_nil }
      end
    end
  end

  describe "as a drop-in replacement for SingleLargeLeaps" do
    let(:options) { {recovery: %i[consonant_triad any_step repetition opposite_leap_within]} }

    context "with no notes" do
      it { is_expected.to be_adherent }
    end

    context "with leaps" do
      context "when recovered by step in the opposite direction" do
        before { place_pitches %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }

        it { is_expected.to be_adherent }
      end

      context "when followed by skip in the opposite direction" do
        before { place_pitches %w[D4 F4 E4 D4 G4 E4 A4 G4 F4 E4 D4] }

        it { is_expected.to be_adherent }
      end

      context "when followed by large leap in the opposite direction" do
        before { place_pitches %w[D4 F4 E4 D4 G4 D4 E4 A4 G4 F4 E4 D4] }

        it { is_expected.to be_adherent }
      end

      context "when followed by leap in the same direction" do
        before { place_pitches %w[D4 A4 C#5 D5] }

        its(:fitness) { is_expected.to be < 1 }
      end

      context "when followed by step in same direction" do
        before { place_pitches %w[D4 F4 E4 D4 G4 A4 G4 F4 E4 D4] }

        it { is_expected.to be_adherent }
      end

      context "when not recovered, but spelling a triad" do
        before { place_pitches %w[D4 F4 E4 D4 G4 B4 G4 F4 E4 D4] }

        it { is_expected.to be_adherent }
      end

      context "when recovered by skip spelling a triad" do
        let(:composition) { HeadMusic::Content::Composition.new(key_signature: "F lydian") }

        before do
          # FUX example
          place_pitches %w[F4 G4 A4 F4 D4 E4 F4 C5 A4 F4 G4 F4]
        end

        it { is_expected.to be_adherent }
        its(:first_mark_code) { is_expected.to be_nil }
      end
    end
  end

  describe "DiatonicInterval::Category#large_leap?" do
    it "is untouched by the configurable guideline" do
      expect(HeadMusic::Analysis::DiatonicInterval::Category.new(4)).to be_large_leap
      expect(HeadMusic::Analysis::DiatonicInterval::Category.new(3)).not_to be_large_leap
    end
  end
end
