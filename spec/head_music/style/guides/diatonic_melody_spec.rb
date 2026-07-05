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

    let(:composition) { HeadMusic::Notation::ABC.parse(abc) }
    let(:voice) { composition.voices.first }

    let(:climax_message) { "Peak on a consonant high or low note one time or twice with a step between." }
    let(:maximum_notes_message) { "Write up to thirty-two notes." }

    context "with Three Blind Mice" do
      let(:three_blind_mice_phrase) { "E2D C3|" }
      let(:see_how_they_run_phrase) { "G2F F2E|" }
      let(:they_all_ran_phrase) { "GccBAB|c2G G3|" }

      context "with the opening phrases" do
        let(:abc) do
          <<~ABC
            X:1
            T:Three Blind Mice (opening phrases)
            M:6/8
            L:1/8
            K:C
            #{three_blind_mice_phrase * 2}#{see_how_they_run_phrase * 2}
          ABC
        end

        it { is_expected.not_to be_adherent }

        it "objects only to the climax note recurring in each 'see how they run' phrase" do
          expect(analysis.messages).to eq([climax_message])
        end

        it "scores well despite the repeated climax" do
          expect(analysis.fitness).to be_between(0.9, 1.0).exclusive
        end
      end

      context "with the full round" do
        let(:abc) do
          <<~ABC
            X:1
            T:Three Blind Mice
            M:6/8
            L:1/8
            K:C
            #{three_blind_mice_phrase * 2}#{see_how_they_run_phrase * 2}
            #{they_all_ran_phrase * 2}#{three_blind_mice_phrase}
          ABC
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
      # "Twin-kle twin-kle lit-tle star": quarters with a half at each phrase end
      let(:first_couplet) { "CCGG|AAG2|FFEE|DDC2|" }
      let(:up_above_the_world_couplet) { "GGFF|EED2|" * 2 }

      context "with the first couplet" do
        let(:abc) do
          <<~ABC
            X:1
            T:Twinkle, Twinkle, Little Star (first couplet)
            M:4/4
            L:1/4
            K:C
            #{first_couplet}
          ABC
        end

        it { is_expected.not_to be_adherent }

        it "objects only to the immediately repeated climax on 'little'" do
          expect(analysis.messages).to eq([climax_message])
        end

        it "scores well despite the repeated climax" do
          expect(analysis.fitness).to be_between(0.9, 1.0).exclusive
        end
      end

      context "with the whole song" do
        let(:abc) do
          <<~ABC
            X:1
            T:Twinkle, Twinkle, Little Star
            M:4/4
            L:1/4
            K:C
            #{first_couplet}#{up_above_the_world_couplet}#{first_couplet}
          ABC
        end

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
      # the eight-bar A section in C major
      let(:abc) do
        <<~ABC
          X:1
          T:Over the Rainbow
          M:4/4
          L:1/8
          K:C
          C4c4|      % Some-where
          B2GAB2c2|  % o-ver the rain-bow
          C4A4|      % way up
          G8|        % high
          A,4F4|     % There's a
          E2CDE2F2|  % land that I heard of
          D2B,CD2E2| % once in a lul-la
          C8|        % by
        ABC
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
