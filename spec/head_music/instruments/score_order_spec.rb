require "spec_helper"

describe HeadMusic::Instruments::ScoreOrder do
  describe ".get" do
    it "returns a ScoreOrder instance for a valid ensemble type" do
      order = described_class.get(:orchestral)
      expect(order).to be_a(described_class)
      expect(order.ensemble_type_key).to eq(:orchestral)
    end

    it "returns nil for an invalid ensemble type" do
      expect(described_class.get(:invalid_type)).to be_nil
    end

    it "caches instances" do
      order1 = described_class.get(:orchestral)
      order2 = described_class.get(:orchestral)
      expect(order1).to be(order2)
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

    it "places unknown instruments at the end" do
      instruments_with_unknown = instruments + ["kazoo"]
      ordered = described_class.in_orchestral_order(instruments_with_unknown)
      instrument_names = ordered.map(&:name)

      expect(instrument_names.last).to eq("kazoo")
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
          timpani
          harp piano
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

    context "with mixed valid and invalid instrument names" do
      let(:instruments) { ["flute", "not_an_instrument", "violin", nil, ""] }

      it "handles invalid entries gracefully" do
        ordered = orchestral_order.order(instruments)
        instrument_names = ordered.map(&:name)

        expect(instrument_names).to include("flute")
        expect(instrument_names).to include("violin")
        expect(instrument_names.size).to eq(3) # flute, violin, and "not_an_instrument"
      end
    end
  end

  describe "#instrument_order" do
    let(:score_order) { described_class.get(:orchestral) }

    it "returns all instruments in order as symbols" do
      order = score_order.instrument_order

      expect(order).to be_an(Array)
      expect(order.first).to be_a(Symbol)
      expect(order).to include(:flute, :violin, :trumpet, :timpani)
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
end
