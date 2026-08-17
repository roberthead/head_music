require "spec_helper"

describe HeadMusic::Style::Guide do
  guides = HeadMusic::Style::Guides

  describe ".get" do
    it "resolves a guide class by string key" do
      expect(described_class.get("first_species_harmony")).to eq guides::FirstSpeciesHarmony
    end

    it "resolves a guide class by symbol key" do
      expect(described_class.get(:first_species_harmony)).to eq guides::FirstSpeciesHarmony
    end

    it "resolves a guide that knows its own category" do
      expect(described_class.get("first_species_harmony").category).to eq :harmony
    end

    it "returns nil for an unknown key" do
      expect(described_class.get("does_not_exist")).to be_nil
    end

    it "does not raise for an unknown key" do
      expect { described_class.get("does_not_exist") }.not_to raise_error
    end

    it "treats nil as a miss" do
      expect(described_class.get(nil)).to be_nil
    end

    it "treats an empty string as a miss" do
      expect(described_class.get("")).to be_nil
    end

    # A contour is a configuration value, not a guide key: a consumer storing
    # "arch" must migrate to "arch_contour_melody".
    it "treats a bare contour name as a miss" do
      expect(described_class.get("ascending")).to be_nil
    end

    it "passes a guide class through unchanged" do
      expect(described_class.get(guides::FuxCantusFirmus)).to be guides::FuxCantusFirmus
    end

    it "passes a configured guide through unchanged" do
      configured_guide = guides::ContourMelody.with(contour: :wave, minimum_melodic_intervals: 3)
      expect(described_class.get(configured_guide)).to be configured_guide
    end
  end

  describe ".get!" do
    it "returns the guide for a known key" do
      expect(described_class.get!("fux_cantus_firmus")).to eq guides::FuxCantusFirmus
    end

    it "raises a KeyError naming the unknown key" do
      expect { described_class.get!("does_not_exist") }.to raise_error(KeyError, /does_not_exist/)
    end
  end

  describe ".known?" do
    it "is true for a registered key" do
      expect(described_class).to be_known("wave_contour_melody")
    end

    it "is false for an unregistered key" do
      expect(described_class).not_to be_known("does_not_exist")
    end

    it "is true for a registered guide object, matching key_for" do
      entry = described_class.get("wave_contour_melody")

      expect(described_class).to be_known(entry)
      expect(described_class.key_for(entry)).to eq "wave_contour_melody"
    end

    # known? must not simply ask whether the argument answers analyze, or it
    # would disagree with key_for about the very same object.
    it "is false for an ad-hoc configuration the registry does not hold" do
      ad_hoc = HeadMusic::Style::Guides::ContourMelody.with(contour: :wave, minimum_melodic_intervals: 3)

      expect(described_class).not_to be_known(ad_hoc)
      expect(described_class.key_for(ad_hoc)).to be_nil
    end

    it "is false for the unconfigured contour guide class" do
      expect(described_class).not_to be_known(HeadMusic::Style::Guides::ContourMelody)
    end
  end

  describe ".all" do
    it "enumerates every registered guide" do
      expect(described_class.all.length).to eq 23
    end

    it "registers each guide once" do
      expect(described_class.all.uniq.length).to eq described_class.all.length
    end

    it "categorizes every guide as melody or harmony" do
      expect(described_class.all.map(&:category).uniq).to match_array %i[melody harmony]
    end

    it "gives every guide something to assess with" do
      expect(described_class.all).to all(respond_to(:assess_items))
    end

    # Properties every guide must hold, checked across the whole registry rather
    # than guide by guide. These replace the throwaway corpus script as the
    # durable evidence: the script proves what the grades were on one day, these
    # prove the shape holds for a guide added later.
    describe "assessability" do
      # Named so a failure says which guide and which length broke, rather than
      # only which value mismatched across twenty-three guides.
      def each_guide_and_length(counts)
        described_class.all.each do |guide|
          counts.each { |count| yield guide, count, described_class.key_for(guide) }
        end
      end

      def solo(pitch_count)
        composition = HeadMusic::Content::Composition.new(key_signature: "D dorian")
        voice = composition.add_voice(role: :counterpoint)
        %w[D4 F4 E4 G4 F4 A4 G4 F4].first(pitch_count).each_with_index do |pitch, bar|
          voice.place("#{bar + 1}:1", :whole, pitch)
        end
        voice
      end

      # Without a precondition a guide finds no fault in an empty voice and
      # calls that a perfect grade -- "no fault found" and "nothing to find
      # fault in" are different claims.
      it "declares at least one precondition for every guide" do
        expect(described_class.all).to all(satisfy { |guide| guide.items_by_tier[:gate].any? })
      end

      it "grades an empty voice zero and says it cannot be assessed" do
        described_class.all.each do |guide|
          assessment = guide.assess(solo(0))

          expect(assessment.fitness).to eq(0.0), "#{described_class.key_for(guide)} graded an empty voice #{assessment.fitness}"
          expect(assessment).not_to be_assessable
        end
      end

      # The harmony guides used to raise here: they reach for a companion voice
      # that a solo voice does not have.
      it "grades rather than raises for a voice with no companion" do
        each_guide_and_length([0, 1, 8]) do |guide, count, key|
          expect { guide.assess(solo(count)).fitness }.not_to raise_error, "#{key} raised at #{count} notes"
        end
      end

      it "never calls an unassessable voice perfect" do
        each_guide_and_length(0..8) do |guide, count, key|
          assessment = guide.assess(solo(count))

          expect(assessment.fitness).to be < 1.0, "#{key} called an unassessable #{count}-note voice perfect" unless assessment.assessable?
        end
      end

      # Below the gate, a longer attempt is nearer to being assessable, and the
      # grade says so. Not claimed above the gate, where a longer melody may
      # legitimately be worse.
      it "never scores a shorter unassessable attempt above a longer one" do
        described_class.all.each do |guide|
          unassessable = (0..8).map { |count| guide.assess(solo(count)) }.reject(&:assessable?)
          fitnesses = unassessable.map(&:fitness)

          expect(fitnesses).to eq(fitnesses.sort), "#{described_class.key_for(guide)} was not monotonic: #{fitnesses.inspect}"
        end
      end

      it "stops at a failed gate rather than grading the rubric anyway" do
        described_class.all.each do |guide|
          assessment = guide.assess(solo(0))

          expect(assessment.guide_item_assessments.map(&:tier).uniq).to eq([:gate]),
            "#{described_class.key_for(guide)} graded rubric items for an unassessable voice"
        end
      end
    end

    # Every configured guide resolves its items at require time so that nothing
    # is written to after load and concurrent lookups cannot race on the memo.
    # Configured resolves guide_items in its constructor, so this holds for a
    # configuration built anywhere, not only for the registry's own warm-up
    # pass (Guide::ALL.each(&:guide_items)).
    it "resolves every configured guide's items at load rather than on first use" do
      configured = described_class.all.reject { |guide| guide.is_a?(Class) }

      expect(configured).to all(satisfy { |guide| guide.instance_variable_defined?(:@guide_items) })
    end

    it "names every guide" do
      expect(described_class.all.map(&:display_name)).to all(be_a(String).and(match(/\S/)))
    end

    # Six of the entries share one class, so a display_name falling back to the
    # class would render all six as "Contour Melody" in a consumer's picker.
    it "names each guide distinctly" do
      names = described_class.all.map(&:display_name)

      expect(names.uniq.length).to eq names.length
    end
  end

  describe ".keys" do
    # Seventeen of these are derived from class names, so a rename would change
    # a value consumers have persisted -- silently, and with every other example
    # here still green. Spelled out literally so that rename has to come here
    # and be acknowledged. Doubles as the catalog of what the gem offers.
    let(:published_keys) do
      %w[
        arch_contour_melody
        ascending_contour_melody
        combined_first_second_third_species_harmony
        combined_first_second_third_species_melody
        descending_contour_melody
        diatonic_melody
        fifth_species_harmony
        fifth_species_melody
        first_species_harmony
        first_species_melody
        fourth_species_harmony
        fourth_species_melody
        fux_cantus_firmus
        salzer_schachter_cantus_firmus
        second_species_harmony
        second_species_melody
        static_contour_melody
        third_species_harmony
        third_species_melody
        third_species_triple_meter_harmony
        third_species_triple_meter_melody
        valley_contour_melody
        wave_contour_melody
      ]
    end

    it "publishes exactly these keys" do
      expect(described_class.keys).to match_array published_keys
    end

    it "returns twenty-three unique keys" do
      expect(described_class.keys.uniq.length).to eq 23
    end

    it "returns strings, since keys cross the storage boundary" do
      expect(described_class.keys).to all(be_a(String))
    end

    it "resolves every key it reports" do
      expect(described_class.keys.map { |key| described_class.get(key) }).to eq described_class.all
    end
  end

  describe ".key_for" do
    it "returns the registered key of a guide class" do
      expect(described_class.key_for(guides::FuxCantusFirmus)).to eq "fux_cantus_firmus"
    end

    it "returns the registered key of a configured guide" do
      expect(described_class.key_for(described_class.get("wave_contour_melody"))).to eq "wave_contour_melody"
    end

    it "returns nil for a configuration that is not in the registry" do
      ad_hoc = guides::ContourMelody.with(contour: :wave, minimum_melodic_intervals: 3)
      expect(described_class.key_for(ad_hoc)).to be_nil
    end
  end

  describe ".display_name_for" do
    it "derives a title from the key" do
      expect(described_class.display_name_for("first_species_harmony")).to eq "First Species Harmony"
    end

    it "prefers a locale entry where the derived title would be wrong" do
      expect(described_class.display_name_for("salzer_schachter_cantus_firmus"))
        .not_to eq "Salzer Schachter Cantus Firmus"
    end

    it "still names the guide when overriding the derived title" do
      expect(described_class.display_name_for("salzer_schachter_cantus_firmus"))
        .to match(/Salzer.Schachter Cantus Firmus/)
    end
  end

  describe "contour guide keys" do
    {
      "arch_contour_melody" => {contour: :arch, minimum_melodic_intervals: 2},
      "ascending_contour_melody" => {contour: :ascending, minimum_melodic_intervals: 1},
      "descending_contour_melody" => {contour: :descending, minimum_melodic_intervals: 1},
      "static_contour_melody" => {contour: :static, minimum_melodic_intervals: nil},
      "valley_contour_melody" => {contour: :valley, minimum_melodic_intervals: 2},
      "wave_contour_melody" => {contour: :wave, minimum_melodic_intervals: 2}
    }.each do |key, options|
      it "resolves #{key} to a configured contour melody guide" do
        expect(described_class.get(key)).to configured_guide(guides::ContourMelody, **options)
      end

      it "keeps #{key} a melodic guide" do
        expect(described_class.get(key).category).to eq :melody
      end

      it "displays #{key} distinctly from its siblings" do
        expect(described_class.get(key).display_name).to eq(
          key.tr("_", " ").split.map(&:capitalize).join(" ")
        )
      end
    end
  end
end
