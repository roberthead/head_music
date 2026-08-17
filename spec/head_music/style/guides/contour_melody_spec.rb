require "spec_helper"

describe HeadMusic::Style::Guides::ContourMelody do
  guidelines = HeadMusic::Style::Guidelines

  # The six registry entries that replace the former contour subclasses. Every
  # structural assertion the six specs made is parameterized over this table.
  contour_rows = [
    {key: "arch_contour_melody", contour: :arch, minimum_melodic_intervals: 2, size: 13},
    {key: "ascending_contour_melody", contour: :ascending, minimum_melodic_intervals: 1, size: 13},
    {key: "descending_contour_melody", contour: :descending, minimum_melodic_intervals: 1, size: 13},
    {key: "static_contour_melody", contour: :static, minimum_melodic_intervals: nil, size: 12},
    {key: "valley_contour_melody", contour: :valley, minimum_melodic_intervals: 2, size: 13},
    {key: "wave_contour_melody", contour: :wave, minimum_melodic_intervals: 2, size: 13}
  ]

  describe ".guide_items" do
    let(:peer_weight) { HeadMusic::GOLDEN_RATIO_INVERSE**2 / 10 }

    it "does not mutate the shared diatonic melody primary items" do
      expect(HeadMusic::Style::Guides::DiatonicMelody.primary_items).to all(
        satisfy { |item| !item.config.key?(:weight) }
      )
    end

    contour_rows.each do |row|
      context "for the #{row[:contour]} contour" do
        let(:guide_items) { HeadMusic::Style::Guide.get(row[:key]).guide_items }

        it "assembles #{row[:size]} rules" do
          expect(guide_items.length).to eq row[:size]
        end

        it "carries every diatonic melody guideline" do
          expect(guide_items.map(&:guideline)).to include(
            *guidelines_of(HeadMusic::Style::Guides::DiatonicMelody)
          )
        end

        it "passes the note-count gate through unchanged" do
          expect(guide_items).to include(configured(guidelines::MinimumNotes, minimum: 5))
        end

        if row[:minimum_melodic_intervals]
          it "gates on at least #{row[:minimum_melodic_intervals]} moving melodic interval(s)" do
            expect(guide_items).to include(
              configured(guidelines::MinimumMelodicIntervals, minimum: row[:minimum_melodic_intervals])
            )
          end
        else
          it "omits the motion gate so a repeated-note line can score" do
            expect(guide_items.map(&:guideline)).not_to include(guidelines::MinimumMelodicIntervals)
          end
        end

        it "weights each rubric peer evenly within the phi^-2 budget" do
          peers = guide_items.reject(&:default_gate?).reject do |entry|
            entry.guideline == guidelines::Contoured
          end
          expect(peers.length).to eq 10
          expect(peers).to all(have_attributes(config: hash_including(weight: peer_weight)))
        end

        it "adds the #{row[:contour]} contour guideline" do
          expect(guide_items).to include(configured(guidelines::Contoured, contour: row[:contour]))
        end
      end
    end

    it "builds the same guide items from a direct configuration as from the registry" do
      direct = described_class.with(contour: :arch, minimum_melodic_intervals: 2).guide_items
      registered = HeadMusic::Style::Guide.get("arch_contour_melody").guide_items
      expect(direct).to eq registered
    end
  end

  describe "contextual weights" do
    let(:voice) { HeadMusic::Content::Voice.new }
    let(:guide_items) { HeadMusic::Style::Guide.get("arch_contour_melody").guide_items }

    it "weights the contour guideline at its default among the guide's items" do
      entry = guide_items.detect { |item| item.guideline == guidelines::Contoured }
      expect(entry.new(voice).weight).to eq HeadMusic::GOLDEN_RATIO_INVERSE
    end

    it "honors a per-context weight override" do
      guideline = guidelines::Contoured.with(:arch, weight: 0.25).new(voice)
      expect(guideline.weight).to eq 0.25
    end

    it "weights the same guideline differently as a rubric peer than standalone" do
      peer = guide_items.detect { |item| item.guideline == guidelines::Diatonic }
      expect(peer.new(voice).weight).to eq(HeadMusic::GOLDEN_RATIO_INVERSE**2 / 10)
      expect(guidelines::Diatonic.new(voice).weight).to eq 1.0
    end
  end

  describe ".with" do
    it "returns a configured guide" do
      expect(described_class.with(contour: :arch, minimum_melodic_intervals: 2)).to be_a(
        HeadMusic::Style::Guides::Configured
      )
    end

    it "normalizes the contour at configuration time" do
      expect(described_class.with(contour: "Arch", minimum_melodic_intervals: 2)).to configured_guide(
        described_class, contour: :arch, minimum_melodic_intervals: 2
      )
    end

    # No analyze call in these: lazy validation would defer the error to grading
    # time, and a spec written around .analyze would pass while the criterion
    # silently did not hold.
    it "rejects a contour outside the closed set" do
      expect { described_class.with(contour: :spiral) }.to raise_error(ArgumentError)
    end

    it "rejects an invalid contour layered onto a valid configuration" do
      configured_arch = described_class.with(contour: :arch, minimum_melodic_intervals: 2)
      expect { configured_arch.with(contour: :spiral) }.to raise_error(ArgumentError)
    end

    it "rejects a misspelled option name" do
      expect { described_class.with(contur: :arch) }.to raise_error(ArgumentError)
    end

    it "requires a contour" do
      expect { described_class.with(minimum_melodic_intervals: 2) }.to raise_error(ArgumentError)
    end
  end

  describe ".analyze" do
    let(:voice) { HeadMusic::Content::Voice.new }

    # Without the .with indirection this would silently grade against whatever
    # items_by_tier produced with no configuration -- but items_by_tier requires
    # a contour keyword, so there is no unconfigured ruleset left to fall back
    # to silently.
    it "refuses to analyze without a configuration" do
      expect { described_class.analyze(voice) }.to raise_error(ArgumentError)
    end

    it "names both ways to configure it, since the bare class reaches Analysis" do
      expect { described_class.analyze(voice) }.to raise_error(
        ArgumentError, /\.with\(contour:.*Guide\.get\("arch_contour_melody"\)/m
      )
    end

    # The class is a valid argument to Analysis.new -- it answers analyze -- so
    # the guard cannot catch this one. Failing at annotations is the backstop.
    it "fails through Analysis rather than grading against the wrong ruleset" do
      analysis = HeadMusic::Style::GuideAssessment.new(described_class, voice)

      expect { analysis.annotations }.to raise_error(ArgumentError, /requires configuration/)
    end
  end

  # ContourMelody does not declare tiers in its class body; it overrides
  # .items_by_tier with required keywords because its lists depend on
  # configuration. .guide_items calls .items_by_tier with no arguments, so an
  # unconfigured read raises ArgumentError here rather than silently resolving
  # some ancestor's items -- the same defense a bare ::RULESET constant lookup
  # used to provide via NameError, before tiers replaced the constant.
  describe "when unconfigured" do
    it "raises rather than silently reaching an inherited ancestor's items" do
      expect { described_class.guide_items }.to raise_error(ArgumentError, /missing keyword: :contour/)
    end

    it "does not leak the diatonic guide items through inheritance" do
      expect(described_class.ancestors).not_to include(HeadMusic::Style::Guides::DiatonicMelody)
    end
  end

  describe "analysis" do
    subject(:analysis) { HeadMusic::Style::GuideAssessment.new(guide, voice) }

    let(:guide) { HeadMusic::Style::Guide.get(guide_key) }
    let(:composition) { HeadMusic::Notation::ABC.parse(abc) }
    let(:voice) { composition.voices.first }

    let(:abc) do
      <<~ABC
        X:1
        M:4/4
        L:1/4
        K:C
        #{melody}
      ABC
    end

    context "with the arch contour guide" do
      let(:guide_key) { "arch_contour_melody" }
      let(:contour_message) { "Write a melody with the arch contour." }

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
          worst = rubric.max_by { |guideline| guideline.weight * (1 - guideline.fitness) }
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
          rubric.sum { |guideline| guideline.weight * guideline.fitness } / rubric.sum(&:weight)
        end

        it "passes the motion gate" do
          motion_gate = analysis.annotations.detect do |guideline|
            guideline.is_a?(HeadMusic::Style::Guidelines::MinimumMelodicIntervals)
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
          HeadMusic::Style::GuideAssessment.new(guide, voice)
        end

        def diatonic_guideline(analysis)
          analysis.annotations.detect do |guideline|
            guideline.is_a?(HeadMusic::Style::Guidelines::Diatonic)
          end
        end

        it "flags only the chromatic notes in both melodies" do
          expect(short_analysis.messages).to eq ["Use only notes in the key signature."]
          expect(long_analysis.messages).to eq ["Use only notes in the key signature."]
        end

        it "scores the diatonic rule identically at one violation in eight notes" do
          expect(diatonic_guideline(long_analysis).fitness)
            .to be_within(1e-12).of(diatonic_guideline(short_analysis).fitness)
        end

        it "grades the two melodies the same overall" do
          expect(long_analysis.fitness).to be_within(1e-6).of(short_analysis.fitness)
        end
      end
    end

    context "with the ascending contour guide" do
      let(:guide_key) { "ascending_contour_melody" }
      let(:contour_message) { "Write a melody with the ascending contour." }

      context "with an undulating-yet-ascending melody" do
        let(:melody) { "CDED|EFEF|G4|" }

        it "does not object to the contour" do
          expect(analysis.messages).not_to include(contour_message)
        end

        it "does not object to the direction changes either" do
          expect(analysis).to be_adherent
        end

        it "grades a perfect submission at one" do
          expect(analysis.fitness).to eq 1.0
        end
      end

      context "with an arching melody" do
        let(:melody) { "CDEG|EDC2|" }

        it "objects to the contour" do
          expect(analysis.messages).to include(contour_message)
        end
      end
    end

    context "with the descending contour guide" do
      let(:guide_key) { "descending_contour_melody" }
      let(:contour_message) { "Write a melody with the descending contour." }

      context "with an undulating melody from ceiling to floor" do
        let(:melody) { "GFEF|EDED|C4|" }

        it "does not object to the contour" do
          expect(analysis.messages).not_to include(contour_message)
        end

        it "grades a perfect submission at one" do
          expect(analysis.fitness).to eq 1.0
        end
      end

      context "with an ascending melody" do
        let(:melody) { "CDED|EFG2|" }

        it "objects to the contour" do
          expect(analysis.messages).to include(contour_message)
        end
      end
    end

    context "with the static contour guide" do
      let(:guide_key) { "static_contour_melody" }
      let(:contour_message) { "Write a melody with the static contour." }

      context "with a narrow-range melody with neutral endpoints" do
        let(:melody) { "EDEF|EFED|E4|" }

        it "does not object to the contour" do
          expect(analysis.messages).not_to include(contour_message)
        end

        it "grades a perfect submission at one" do
          expect(analysis.fitness).to eq 1.0
        end
      end

      context "with an all-repeated-note line" do
        let(:melody) { "E4|E4|E4|E4|E4|" }

        it "does not object to the contour" do
          expect(analysis.messages).not_to include(contour_message)
        end

        it "does not gate the grade to zero" do
          expect(analysis.fitness).to be > 0.9
        end

        it "passes every gate" do
          gates = analysis.annotations.select(&:gate?)
          expect(gates.map(&:fitness)).to all(eq(1.0))
        end
      end

      context "with a melody spanning a fifth" do
        let(:melody) { "CDEF|G4|" }

        it "objects to the contour" do
          expect(analysis.messages).to include(contour_message)
        end
      end
    end

    context "with the valley contour guide" do
      let(:guide_key) { "valley_contour_melody" }
      let(:contour_message) { "Write a melody with the valley contour." }

      context "with an interior nadir" do
        let(:melody) { "GFEC|DEFG|" }

        it "does not object to the contour" do
          expect(analysis.messages).not_to include(contour_message)
        end
      end

      context "with an interior nadir and a single peak" do
        let(:melody) { "GFED|CDEF|" }

        it "grades a perfect submission at one" do
          expect(analysis.fitness).to eq 1.0
        end

        it "is adherent" do
          expect(analysis).to be_adherent
        end
      end

      context "with a melody bottoming out on the last note" do
        let(:melody) { "GFED|C4|" }

        it "objects to the contour" do
          expect(analysis.messages).to include(contour_message)
        end
      end
    end

    context "with the wave contour guide" do
      let(:guide_key) { "wave_contour_melody" }
      let(:contour_message) { "Write a melody with the wave contour." }

      context "with three trend legs" do
        let(:melody) { "CDED|CDE2|" }

        it "does not object to the contour" do
          expect(analysis.messages).not_to include(contour_message)
        end
      end

      context "with four trend legs and a single peak" do
        let(:melody) { "CDED|CDEF|EDC2|" }

        it "grades a perfect submission at one" do
          expect(analysis.fitness).to eq 1.0
        end

        it "is adherent" do
          expect(analysis).to be_adherent
        end
      end

      context "with a single-turn arch" do
        let(:melody) { "CDEG|EDC2|" }

        it "objects to the contour" do
          expect(analysis.messages).to include(contour_message)
        end
      end
    end
  end
end
