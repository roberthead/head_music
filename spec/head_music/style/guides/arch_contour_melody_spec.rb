require "spec_helper"

describe HeadMusic::Style::Guides::ArchContourMelody do
  describe "RULESET" do
    let(:ruleset) { described_class::RULESET }
    let(:peer_weight) { HeadMusic::GOLDEN_RATIO_INVERSE**2 / 10 }

    it "carries every diatonic melody guideline" do
      diatonic_classes = HeadMusic::Style::Guides::DiatonicMelody::RULESET.map do |entry|
        entry.respond_to?(:guideline_class) ? entry.guideline_class : entry
      end
      expect(ruleset.map(&:guideline_class)).to include(*diatonic_classes)
    end

    it "passes the note-count gate through unchanged" do
      expect(ruleset).to include(
        configured(HeadMusic::Style::Guidelines::MinimumNotes, minimum: 5)
      )
    end

    it "gates on at least two moving melodic intervals" do
      expect(ruleset).to include(
        configured(HeadMusic::Style::Guidelines::MinimumMelodicIntervals, minimum: 2)
      )
    end

    it "weights each rubric peer evenly within the phi^-2 budget" do
      peers = ruleset.reject(&:default_gate?).reject do |entry|
        entry.guideline_class == HeadMusic::Style::Guidelines::Contoured
      end
      expect(peers.length).to eq 10
      expect(peers).to all(have_attributes(options: hash_including(weight: peer_weight)))
    end

    it "adds the arch contour guideline at its default weight" do
      expect(ruleset).to include(
        configured(HeadMusic::Style::Guidelines::Contoured, contour: :arch)
      )
    end

    it "does not mutate the shared diatonic melody ruleset" do
      expect(HeadMusic::Style::Guides::DiatonicMelody::RULESET).to all(
        satisfy { |entry| !entry.respond_to?(:options) || !entry.options.key?(:weight) }
      )
    end
  end

  describe "contextual weights" do
    let(:voice) { HeadMusic::Content::Voice.new }

    it "weights the contour guideline at its default in the guide ruleset" do
      entry = described_class::RULESET.detect do |rule|
        rule.guideline_class == HeadMusic::Style::Guidelines::Contoured
      end
      expect(entry.new(voice).weight).to eq HeadMusic::GOLDEN_RATIO_INVERSE
    end

    it "honors a per-context weight override" do
      annotation = HeadMusic::Style::Guidelines::Contoured.with(:arch, weight: 0.25).new(voice)
      expect(annotation.weight).to eq 0.25
    end

    it "weights the same guideline differently as a rubric peer than standalone" do
      peer = described_class::RULESET.detect do |rule|
        rule.guideline_class == HeadMusic::Style::Guidelines::Diatonic
      end
      expect(peer.new(voice).weight).to eq(HeadMusic::GOLDEN_RATIO_INVERSE**2 / 10)
      expect(HeadMusic::Style::Guidelines::Diatonic.new(voice).weight).to eq 1.0
    end
  end

  describe "analysis" do
    subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

    let(:composition) { HeadMusic::Notation::ABC.parse(abc) }
    let(:voice) { composition.voices.first }
    let(:contour_message) { "Write a melody with the arch contour." }

    let(:abc) do
      <<~ABC
        X:1
        M:4/4
        L:1/4
        K:C
        #{melody}
      ABC
    end

    context "with an arching melody that satisfies every rule" do
      let(:melody) { "CDEG|EDC2|" }

      it "does not object to the contour" do
        expect(analysis.messages).not_to include(contour_message)
      end

      it "grades a perfect submission at one" do
        expect(analysis.fitness).to eq 1.0
      end

      it "is adherent" do
        expect(analysis).to be_adherent
      end
    end

    context "with a melody climaxing on the last note" do
      let(:melody) { "CDEF|G4|" }

      it "objects to the contour" do
        expect(analysis.messages).to include(contour_message)
      end
    end

    context "with a descending line that satisfies everything but the contour" do
      let(:melody) { "G4|F4|E4|D4|C4|" }

      # The golden identity phi^-1 + phi^-2 = 1: rubric peers share phi^-2
      # of weight and Contoured carries phi^-1, so a wrong contour on an
      # otherwise perfect line grades exactly phi^-1.
      it "grades exactly the inverse golden ratio" do
        expect(analysis.fitness).to be_within(1e-6).of(HeadMusic::GOLDEN_RATIO_INVERSE)
      end

      it "grades below a C" do
        expect(analysis.fitness).to be < 0.70
      end

      it "loses more credit to the contour than to any other rule" do
        rubric = analysis.annotations.reject(&:gate?)
        worst = rubric.max_by { |annotation| annotation.weight * (1 - annotation.fitness) }
        expect(worst).to be_a(HeadMusic::Style::Guidelines::Contoured)
        expect(worst.weight * (1 - worst.fitness)).to be > 0
      end
    end

    context "with a gate-passing melody that is broken across the rubric" do
      # A minor-seventh sawtooth between C and B-flat that climbs an octave
      # to end on the climax: wrong contour for an arch, chromatic, disjunct,
      # wide-ranged, and full of unsingable leaps -- yet a real attempt with
      # eight notes and constant motion, so both gates pass at full credit.
      let(:melody) { "C4|_B4|C4|_B4|C4|_B4|c4|_b4|" }

      it "passes both gates at full credit" do
        gates = analysis.annotations.select(&:gate?)
        expect(gates.map(&:fitness)).to all(eq(1.0))
      end

      it "objects to the contour" do
        expect(analysis.messages).to include(contour_message)
      end

      it "grades into the soft floor rather than near zero" do
        # Rate-normalized rules bottom out near phi^-1 and the weighted
        # arithmetic mean averages them, so broken-but-real work lands
        # substantially below perfect without collapsing toward the gated
        # zero of a non-attempt.
        expect(analysis.fitness).to be_between(0.3, 0.55)
      end
    end

    context "with an empty voice" do
      let(:composition) { HeadMusic::Content::Composition.new(key_signature: "C major") }
      let(:voice) { composition.add_voice(role: :melody) }

      it "gates the grade to zero" do
        expect(analysis.fitness).to eq 0.0
      end

      it "is not adherent" do
        expect(analysis).not_to be_adherent
      end
    end

    context "with a four-note line" do
      let(:melody) { "CD^FE|" }

      let(:rubric_mean) do
        rubric = analysis.annotations.reject(&:gate?)
        rubric.sum { |annotation| annotation.weight * annotation.fitness } / rubric.sum(&:weight)
      end

      it "passes the motion gate" do
        motion_gate = analysis.annotations.detect do |annotation|
          annotation.is_a?(HeadMusic::Style::Guidelines::MinimumMelodicIntervals)
        end
        expect(motion_gate.fitness).to eq 1.0
      end

      it "applies the note-count gate as a proportional haircut on the rubric mean" do
        expect(analysis.fitness).to be_within(1e-9).of(0.8 * rubric_mean)
      end
    end

    context "with the same chromatic violation rate at different lengths" do
      let(:short_analysis) { analysis_for("CDE^F|GEDC|") }
      let(:long_analysis) { analysis_for("CDE^F|GAGE|^FGED|EDCC|") }

      def analysis_for(melody)
        abc = <<~ABC
          X:1
          M:4/4
          L:1/4
          K:C
          #{melody}
        ABC
        voice = HeadMusic::Notation::ABC.parse(abc).voices.first
        HeadMusic::Style::Analysis.new(described_class, voice)
      end

      def diatonic_annotation(analysis)
        analysis.annotations.detect do |annotation|
          annotation.is_a?(HeadMusic::Style::Guidelines::Diatonic)
        end
      end

      it "flags only the chromatic notes in both melodies" do
        expect(short_analysis.messages).to eq ["Use only notes in the key signature."]
        expect(long_analysis.messages).to eq ["Use only notes in the key signature."]
      end

      it "scores the diatonic rule identically at one violation in eight notes" do
        expect(diatonic_annotation(long_analysis).fitness)
          .to be_within(1e-12).of(diatonic_annotation(short_analysis).fitness)
      end

      it "grades the two melodies the same overall" do
        expect(long_analysis.fitness).to be_within(1e-6).of(short_analysis.fitness)
      end
    end
  end
end
