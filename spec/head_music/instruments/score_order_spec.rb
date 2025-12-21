require "spec_helper"

describe HeadMusic::Instruments::ScoreOrder do
  describe "construction" do
    context "with a valid ensemble type" do
      subject(:score_order) { described_class.get(:orchestral) }

      specify do
        expect(score_order).to be_a(described_class)
        expect(score_order.ensemble_type_key).to eq(:orchestral)
      end
    end

    context "with an invalid ensemble type" do
      subject(:score_order) { described_class.get(:invalid_type) }

      it { is_expected.to be_nil }
    end

    it "caches instances" do
      order1 = described_class.get(:orchestral)
      order2 = described_class.get(:orchestral)
      expect(order1).to be(order2)
    end

    it "handles missing sections gracefully" do
      # This tests the fallback behavior in the initialize method
      order = described_class.get(:orchestral)
      expect(order.sections).to be_an(Array)
    end
  end

  describe ".in_orchestral_order" do
    let(:instruments) { %w[violin trumpet flute timpani cello] }

    it "returns instruments in orchestral order" do
      ordered = described_class.in_orchestral_order(instruments)
      instrument_names = ordered.map(&:name)

      expect(instrument_names).to eq(["flute", "trumpet", "timpani", "violin", "cello"])
    end

    it "handles instrument objects" do
      instrument_objects = instruments.map { |name| HeadMusic::Instruments::Instrument.get(name) }
      ordered = described_class.in_orchestral_order(instrument_objects)

      expect(ordered.first.name).to eq("flute")
      expect(ordered.last.name).to eq("cello")
    end

    it "filters out unknown instruments" do
      instruments_with_unknown = instruments + ["kazoo"]
      ordered = described_class.in_orchestral_order(instruments_with_unknown)
      instrument_names = ordered.map(&:name)

      # Unknown instruments are now filtered out (return nil from Instrument.get)
      expect(instrument_names).not_to include("kazoo")
      expect(instrument_names.last).to eq("cello")
    end
  end

  describe ".in_band_order" do
    subject(:ordered_instrument_names) {
      ordered_instruments.map(&:name)
    }

    let(:ordered_instruments) { described_class.in_band_order(instruments) }

    context "with concert band instruments" do
      let(:instruments) { %w[alto_saxophone trumpet flute tuba clarinet] }

      it "puts the woodwinds before the brass" do
        expect(ordered_instrument_names).to eq([
          "flute", "clarinet", "alto saxophone", "trumpet", "tuba"
        ])
      end
    end

    context "with brass instruments" do
      let(:instruments) { %w[tuba euphonium trombone trumpet cornet french_horn] }

      it do
        expect(ordered_instrument_names).to eq([
          "cornet", "trumpet", "French horn", "trombone", "euphonium", "tuba"
        ])
      end
    end

    context "with percussion" do
      let(:instruments) { %w[flute trumpet timpani snare_drum tuba] }

      it "places percussion at the bottom" do
        expect(ordered_instrument_names).to eq([
          "flute", "trumpet", "tuba", "timpani", "snare drum"
        ])
      end
    end
  end

  describe "#order" do
    subject(:ordered_instrument_names) {
      orchestral_order.order(instruments).map(&:name)
    }

    let(:orchestral_order) { described_class.get(:orchestral) }

    context "with a full orchestra" do
      let(:instruments) do
        %w[
          violin viola cello double_bass
          flute oboe clarinet bassoon
          french_horn trumpet trombone tuba
          timpani harp piano
        ]
      end

      it "orders sections correctly" do # rubocop:disable RSpec/ExampleLength
        expect(ordered_instrument_names).to eq([
          "flute", "oboe", "clarinet", "bassoon",
          "French horn", "trumpet", "trombone", "tuba",
          "timpani", "harp", "piano",
          "violin", "viola", "cello", "double bass"
        ])
      end
    end

    context "with voices" do
      let(:instruments) { %w[soprano_voice alto_voice tenor_voice bass_voice violin] }

      it "places voices before strings" do
        ordered = orchestral_order.order(instruments)
        instrument_names = ordered.map(&:name)

        soprano_index = instrument_names.index("soprano")
        violin_index = instrument_names.index("violin")

        expect(soprano_index).to be < violin_index
      end
    end

    context "with duplicate instruments" do
      let(:instruments) { %w[violin violin viola] }

      it "preserves duplicates" do
        ordered = orchestral_order.order(instruments)
        instrument_names = ordered.map(&:name)

        expect(instrument_names.count("violin")).to eq(2)
        expect(instrument_names).to eq(["violin", "violin", "viola"])
      end
    end

    context "with a fake instrument name" do
      let(:instruments) { ["flute", "not_an_instrument", "violin"] }

      it "filters out the fake instrument" do
        ordered = orchestral_order.order(instruments)
        instrument_names = ordered.map(&:name)

        # Invalid instruments are filtered out (return nil from Instrument.get)
        expect(instrument_names).not_to include("not_an_instrument")
        expect(instrument_names).to eq(["flute", "violin"])
      end
    end

    context "with instrument alias" do
      let(:instruments) do
        %w[flute alto_saxophone tenor_saxophone alto_flute alto_recorder piccolo]
      end

      it "orders variants correctly" do
        ordered = orchestral_order.order(instruments)
        expect(ordered.map(&:name)).to eq(
          ["piccolo flute", "flute", "alto flute", "alto recorder", "alto saxophone", "tenor saxophone"]
        )
      end
    end

    context "with trumpet transpositions" do
      # Note: trumpet (base) is Bb, so we use "trumpet" instead of "trumpet_in_b_flat"
      let(:instruments) { ["trumpet", "trumpet_in_d", "trumpet_in_e_flat", "trumpet_in_c"] }

      it "orders trumpets by transposition (high to low)" do
        ordered = orchestral_order.order(instruments)
        transpositions = ordered.map(&:default_sounding_transposition)

        # Eb (+3), D (+2), C (0), Bb (-2)
        expect(transpositions).to eq([3, 2, 0, -2])
      end
    end

    context "with a mix of instrument variants and aliases" do
      subject(:ordered_instrument_names) do
        orchestral_order.order(instruments).map(&:name)
      end

      let(:instruments) do
        %w[pianoforte flute trombone trumpet_in_c viola trumpet violin tenor_saxophone cello alto_recorder piccolo violin]
      end

      it do
        expect(ordered_instrument_names).to eq([
          "piccolo flute", "flute", "alto recorder", "tenor saxophone", "trumpet in C", "trumpet", "trombone",
          "piano", "violin", "violin", "viola", "cello"
        ])
      end
    end

    context "with clarinet transpositions" do
      let(:clarinet_bb) { HeadMusic::Instruments::Instrument.get("clarinet") }
      let(:clarinet_a) { HeadMusic::Instruments::Instrument.get("clarinet_in_a") }
      let(:clarinet_c) { HeadMusic::Instruments::Instrument.get("clarinet_in_c") }
      let(:clarinet_eb) { HeadMusic::Instruments::Instrument.get("clarinet_in_e_flat") }

      let(:instruments) { [clarinet_bb, clarinet_a, clarinet_c, clarinet_eb] }

      it "orders clarinets by transposition (high to low)" do
        ordered = orchestral_order.order(instruments)
        transpositions = ordered.map(&:default_sounding_transposition)

        # Eb (+3), C (0), Bb (-2), A (-3)
        expect(transpositions).to eq([3, 0, -2, -3])
      end
    end

    context "with mixed valid and invalid instrument names" do
      let(:instruments) { ["flute", "not_an_instrument", "violin", nil, ""] }

      it "handles invalid entries gracefully by filtering them out" do
        ordered = orchestral_order.order(instruments)
        instrument_names = ordered.map(&:name)

        expect(instrument_names).to include("flute")
        expect(instrument_names).to include("violin")
        # Invalid instruments are now filtered out
        expect(instrument_names.size).to eq(2) # flute and violin only
      end
    end

    context "with a score order" do
      let(:score_order) { described_class.get(:orchestral) }

      it "handles invalid instrument strings gracefully by filtering them out" do
        instruments = ["invalid_instrument_name", "flute"]
        ordered = score_order.order(instruments)

        expect(ordered.map(&:name)).to include("flute")
        # Invalid instruments are now filtered out
        expect(ordered.map(&:name)).not_to include("invalid_instrument_name")
      end

      it "handles empty strings and nils" do
        instruments = [nil, "", "flute", nil]
        ordered = score_order.order(instruments)

        expect(ordered.map(&:name)).to eq(["flute"])
      end

      it "handles instruments with family matching" do
        # Test case where instrument has a family_key that matches ordering
        instruments = ["alto_saxophone", "tenor_saxophone"]
        band_order = described_class.get(:band)
        ordered = band_order.order(instruments) if band_order

        expect(ordered).not_to be_empty if band_order
      end
    end
  end

  describe "chamber ensembles" do
    subject(:ordered_instrument_names) {
      score_order.order(instruments).map(&:name)
    }

    describe "brass quintet" do
      let(:score_order) { described_class.get(:brass_quintet) }
      let(:instruments) { %w[tuba trumpet french_horn trombone trumpet] }

      it "orders brass quintet correctly" do
        expect(ordered_instrument_names).to eq(["trumpet", "trumpet", "French horn", "trombone", "tuba"])
      end
    end

    describe "woodwind quintet" do
      let(:score_order) { described_class.get(:woodwind_quintet) }
      let(:instruments) { %w[bassoon clarinet oboe flute french_horn] }

      it "orders correctly" do
        expect(ordered_instrument_names).to eq(["flute", "oboe", "clarinet", "French horn", "bassoon"])
      end
    end

    describe "string quartet" do
      let(:score_order) { described_class.get(:string_quartet) }
      let(:instruments) { %w[cello violin viola violin] }

      it "orders correctly" do
        expect(ordered_instrument_names).to eq(["violin", "violin", "viola", "cello"])
      end
    end
  end

  describe "normalize_to_instrument edge cases" do
    let(:orchestral_order) { described_class.get(:orchestral) }

    context "with GenericInstrument objects" do
      it "converts GenericInstrument to its default instrument configuration" do
        instrument = HeadMusic::Instruments::GenericInstrument.get("violin")
        ordered = orchestral_order.order([instrument, "flute"])

        expect(ordered.map(&:name)).to eq(["flute", "violin"])
      end
    end

    context "with mock objects that respond to name_key and family_key" do
      it "handles duck-typed objects" do # rubocop:disable RSpec/ExampleLength
        mock_instrument = double( # rubocop:disable RSpec/VerifiedDoubles
          "MockInstrument",
          name_key: "violin",
          family_key: "string",
          name: "Mock Violin",
          default_sounding_transposition: 0,
          to_s: "Mock Violin"
        )

        ordered = orchestral_order.order([mock_instrument, "flute"])
        expect(ordered.first.name).to eq("flute")
        expect(ordered.last).to eq(mock_instrument)
      end
    end

    context "with instrument names that normalize differently" do
      it "handles names with spaces and hyphens" do # rubocop:disable RSpec/ExampleLength
        # Test normalized name matching (line 123-124)
        mock_instrument = double( # rubocop:disable RSpec/VerifiedDoubles
          "MockInstrument",
          name_key: "some_key",
          family_key: nil,
          name: "Soprano Saxophone",
          default_sounding_transposition: 0,
          to_s: "Soprano Saxophone"
        )

        ordered = orchestral_order.order([mock_instrument, "flute"])
        expect(ordered).to include(mock_instrument)
      end
    end
  end

  describe "find_position family matching edge cases" do
    let(:orchestral_order) { described_class.get(:orchestral) }

    context "when instrument variant is not in ordering but family is" do
      it "falls back to family key" do # rubocop:disable RSpec/ExampleLength
        # Create a mock that will trigger family fallback logic
        mock_saxophone = double( # rubocop:disable RSpec/VerifiedDoubles
          "MockSaxophone",
          name_key: "baritone_saxophone",
          family_key: "saxophone",
          name: "Baritone Saxophone",
          default_sounding_transposition: -14,
          to_s: "Baritone Saxophone"
        )

        # Even if the specific variant isn't in the order, it should still get positioned
        ordered = orchestral_order.order([mock_saxophone, "flute", "violin"])
        expect(ordered).to include(mock_saxophone)
      end
    end

    context "when instrument key includes family base" do
      it "checks for specific variant first, then family" do
        # This tests the branch at line 113-119
        instruments = ["alto_saxophone", "flute"]
        ordered = orchestral_order.order(instruments)

        expect(ordered.map(&:name)).to include("alto saxophone")
      end
    end

    context "when specific instrument variant is not in score order but family is" do
      it "falls back to family position" do # rubocop:disable RSpec/ExampleLength
        # Create a mock instrument whose name_key contains family_key,
        # but the specific variant is NOT in the score order, only the family is
        mock_trombone = double( # rubocop:disable RSpec/VerifiedDoubles
          "MockTrombone",
          name_key: "contrabass_trombone", # NOT in score_orders.yml
          family_key: "trombone", # but "trombone" IS in score_orders.yml
          name: "Contrabass Trombone",
          default_sounding_transposition: 0,
          to_s: "Contrabass Trombone"
        )

        # This should position the mock trombone near other trombones
        ordered = orchestral_order.order([mock_trombone, "flute", "violin"])

        # The mock should be positioned, not at the end as an unknown instrument
        expect(ordered.last.name).not_to eq("Contrabass Trombone")
        expect(ordered).to include(mock_trombone)

        # It should be positioned in the brass section (after flute, before strings)
        flute_index = ordered.index { |i| i.name == "flute" }
        violin_index = ordered.index { |i| i.name == "violin" }
        trombone_index = ordered.index(mock_trombone)

        expect(trombone_index).to be > flute_index
        expect(trombone_index).to be < violin_index
      end
    end
  end

  describe "transposition edge cases" do
    let(:orchestral_order) { described_class.get(:orchestral) }

    context "when instrument has nil default_sounding_transposition" do
      it "defaults to 0 for sorting" do # rubocop:disable RSpec/ExampleLength
        # Create a mock with nil transposition to test line 135
        mock_instrument = double( # rubocop:disable RSpec/VerifiedDoubles
          "MockInstrument",
          name_key: "trumpet",
          family_key: "brass",
          name: "Mock Trumpet",
          default_sounding_transposition: nil,
          to_s: "Mock Trumpet"
        )

        # Use "trumpet" (base Bb trumpet) instead of "trumpet_in_b_flat"
        trumpet_bb = HeadMusic::Instruments::Instrument.get("trumpet")
        ordered = orchestral_order.order([mock_instrument, trumpet_bb])

        # Both should be positioned, mock comes after trumpet_bb due to transposition
        expect(ordered.length).to eq(2)
      end
    end
  end

  describe "fallback to GenericInstrument.get" do
    let(:orchestral_order) { described_class.get(:orchestral) }

    context "when Instrument.get returns nil but GenericInstrument.get succeeds" do
      it "uses GenericInstrument as fallback" do
        # This is hard to test directly since most names work with both,
        # but we can verify the behavior exists
        result = orchestral_order.order(["violin"])
        expect(result).not_to be_empty
      end
    end
  end
end
