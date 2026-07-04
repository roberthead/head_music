require "spec_helper"

describe HeadMusic::Style::Guides::DiatonicMelody do
  let(:ruleset) { described_class::RULESET }

  describe "RULESET" do
    let(:included_guidelines) do
      [
        HeadMusic::Style::Guidelines::ConsonantClimax,
        HeadMusic::Style::Guidelines::Diatonic,
        HeadMusic::Style::Guidelines::LimitOctaveLeaps,
        HeadMusic::Style::Guidelines::ModerateDirectionChanges,
        HeadMusic::Style::Guidelines::MostlyConjunct,
        HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
        HeadMusic::Style::Guidelines::SingableRange,
        configured(HeadMusic::Style::Guidelines::LargeLeaps, minimum: :perfect_fourth, recovery: %i[consonant_triad any_step repetition opposite_leap_within]),
        configured(HeadMusic::Style::Guidelines::SingableIntervals, ascending: described_class::SINGABLE_INTERVALS, descending: described_class::SINGABLE_INTERVALS)
      ]
    end

    let(:omitted_guidelines) do
      [
        HeadMusic::Style::Guidelines::StartOnTonic,
        HeadMusic::Style::Guidelines::EndOnTonic,
        HeadMusic::Style::Guidelines::NoRests,
        HeadMusic::Style::Guidelines::NotesSameLength,
        HeadMusic::Style::Guidelines::StepToFinalNote
      ]
    end

    it "includes the free diatonic melody guidelines" do
      expect(ruleset).to include(*included_guidelines)
    end

    it "omits the cantus-firmus-specific guidelines" do
      expect(ruleset).not_to include(*omitted_guidelines)
    end

    it "permits major sixths in the singable intervals" do
      expect(described_class::SINGABLE_INTERVALS).to include("M6")
    end

    it "replaces the core SingableIntervals with the configured version" do
      expect(ruleset).not_to include(HeadMusic::Style::Guidelines::SingableIntervals)
    end

    describe "loosened note-count range of 5 to 32" do
      def configured_for(guideline_class)
        ruleset.find do |rule|
          rule.is_a?(HeadMusic::Style::Annotation::Configured) && rule.guideline_class == guideline_class
        end
      end

      it "sets a minimum of 5 notes" do
        expect(configured_for(HeadMusic::Style::Guidelines::MinimumNotes).options).to eq(minimum: 5)
      end

      it "sets a maximum of 32 notes" do
        expect(configured_for(HeadMusic::Style::Guidelines::MaximumNotes).options).to eq(maximum: 32)
      end
    end
  end

  describe "analysis of familiar melodies" do
    subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

    let(:composition) do
      HeadMusic::Content::Composition.new(
        name: melody_name,
        key_signature: HeadMusic::Rudiment::KeySignature.get("C major"),
        meter: meter
      )
    end

    # notes is a list of [pitch, rhythmic_value] pairs placed consecutively
    let(:voice) do
      composition.add_voice(role: "melody").tap do |melody_voice|
        notes.each do |pitch, rhythmic_value|
          melody_voice.place(melody_voice.next_position, rhythmic_value, pitch)
        end
      end
    end

    let(:climax_message) { "Peak on a consonant high or low note one time or twice with a step between." }
    let(:maximum_notes_message) { "Write up to thirty-two notes." }

    context "with Three Blind Mice" do
      let(:meter) { "6/8" }

      let(:three_blind_mice_phrase) do
        [["E4", :quarter], ["D4", :eighth], ["C4", :dotted_quarter]]
      end

      let(:see_how_they_run_phrase) do
        [["G4", :quarter], ["F4", :eighth], ["F4", :quarter], ["E4", :eighth]]
      end

      let(:they_all_ran_phrase) do
        [
          ["G4", :eighth], ["C5", :eighth], ["C5", :eighth],
          ["B4", :eighth], ["A4", :eighth], ["B4", :eighth],
          ["C5", :quarter], ["G4", :eighth], ["G4", :dotted_quarter]
        ]
      end

      context "with the opening phrases" do
        let(:melody_name) { "Three Blind Mice (opening phrases)" }
        let(:notes) { three_blind_mice_phrase * 2 + see_how_they_run_phrase * 2 }

        it { is_expected.not_to be_adherent }

        it "objects only to the climax note recurring in each 'see how they run' phrase" do
          expect(analysis.messages).to eq([climax_message])
        end

        it "scores well despite the repeated climax" do
          expect(analysis.fitness).to be_between(0.9, 1.0).exclusive
        end
      end

      context "with the full round" do
        let(:melody_name) { "Three Blind Mice" }
        let(:notes) do
          three_blind_mice_phrase * 2 +
            see_how_they_run_phrase * 2 +
            they_all_ran_phrase * 2 +
            three_blind_mice_phrase
        end

        it { is_expected.not_to be_adherent }

        it "objects to the repeated climax and the length" do
          expect(analysis.messages).to contain_exactly(climax_message, maximum_notes_message)
        end

        it "scores lower at thirty-five notes" do
          expect(analysis.fitness).to be < 0.8
        end
      end
    end

    context "with Twinkle, Twinkle, Little Star" do
      let(:meter) { "4/4" }
      let(:first_couplet) do
        twinkle_phrase(%w[C4 C4 G4 G4 A4 A4 G4]) + twinkle_phrase(%w[F4 F4 E4 E4 D4 D4 C4])
      end
      let(:up_above_the_world_couplet) do
        twinkle_phrase(%w[G4 G4 F4 F4 E4 E4 D4]) * 2
      end

      # six quarter notes ending with a half note, as in "Twin-kle twin-kle lit-tle star"
      def twinkle_phrase(pitches)
        pitches[0..-2].map { |pitch| [pitch, :quarter] } + [[pitches.last, :half]]
      end

      context "with the first couplet" do
        let(:melody_name) { "Twinkle, Twinkle, Little Star (first couplet)" }
        let(:notes) { first_couplet }

        it { is_expected.not_to be_adherent }

        it "objects only to the immediately repeated climax on 'little'" do
          expect(analysis.messages).to eq([climax_message])
        end

        it "scores well despite the repeated climax" do
          expect(analysis.fitness).to be_between(0.9, 1.0).exclusive
        end
      end

      context "with the whole song" do
        let(:melody_name) { "Twinkle, Twinkle, Little Star" }
        let(:notes) { first_couplet + up_above_the_world_couplet + first_couplet }

        it { is_expected.not_to be_adherent }

        it "objects to the repeated climax and the length" do
          expect(analysis.messages).to contain_exactly(climax_message, maximum_notes_message)
        end

        it "scores lower at forty-two notes" do
          expect(analysis.fitness).to be < 0.8
        end
      end
    end

    context "with one verse of Over the Rainbow" do
      let(:meter) { "4/4" }
      let(:melody_name) { "Over the Rainbow" }

      # the eight-bar A section in C major
      let(:notes) do
        [
          ["C4", :half], ["C5", :half],                             # Some-where
          ["B4", :quarter], ["G4", :eighth], ["A4", :eighth],
          ["B4", :quarter], ["C5", :quarter],                       # o-ver the rain-bow
          ["C4", :half], ["A4", :half],                             # way up
          ["G4", :whole],                                           # high
          ["A3", :half], ["F4", :half],                             # There's a
          ["E4", :quarter], ["C4", :eighth], ["D4", :eighth],
          ["E4", :quarter], ["F4", :quarter],                       # land that I heard of
          ["D4", :quarter], ["B3", :eighth], ["C4", :eighth],
          ["D4", :quarter], ["E4", :quarter],                       # once in a lul-la
          ["C4", :whole]                                            # by
        ]
      end

      let(:octave_leaps_message) { "Use a maximum of one octave leap." }
      let(:singable_intervals_message) { "Use only P1, m2, M2, m3, M3, P4, P5, m6, M6, P8 in the melodic line." }

      it { is_expected.not_to be_adherent }

      it "objects to the second octave leap and the minor seventh drop, but not the major sixth" do
        expect(analysis.messages).to contain_exactly(octave_leaps_message, singable_intervals_message)
      end

      it "accepts the climax because the opening octave reads as a descending melody with a single low point" do
        expect(analysis.messages).not_to include(climax_message)
      end

      it "scores in the acceptable range despite the wide leaps" do
        expect(analysis.fitness).to be_between(0.8, 0.9).exclusive
      end
    end
  end
end
