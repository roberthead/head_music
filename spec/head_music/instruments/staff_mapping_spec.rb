require "spec_helper"

describe HeadMusic::Instruments::StaffMapping do
  describe "#initialize" do
    context "when given a staff_position and instrument" do
      subject(:mapping) do
        described_class.new({"staff_position" => 4, "instrument" => "snare_drum"})
      end

      its(:instrument_key) { is_expected.to eq("snare_drum") }

      specify do
        expect(mapping.staff_position.index).to eq(4)
      end
    end

    context "when given an optional playing_technique" do
      subject(:mapping) do
        described_class.new({
          "staff_position" => -1,
          "instrument" => "hi_hat",
          "playing_technique" => "pedal"
        })
      end

      its(:playing_technique_key) { is_expected.to eq("pedal") }
    end

    it "converts staff_position to integer" do
      mapping = described_class.new({"staff_position" => "4", "instrument" => "snare_drum"})
      expect(mapping.position_index).to eq(4)
    end
  end

  describe "#instrument" do
    it "returns the Instrument object for a valid instrument_key" do
      mapping = described_class.new({"staff_position" => 4, "instrument" => "snare_drum"})
      instrument = mapping.instrument
      expect(instrument).to be_a(HeadMusic::Instruments::Instrument)
      expect(instrument.name).to eq("snare drum")
    end

    it "returns nil when instrument_key is nil" do
      mapping = described_class.new({"staff_position" => 4})
      expect(mapping.instrument).to be_nil
    end
  end

  describe "#position_index" do
    it "delegates to staff_position.index" do
      mapping = described_class.new({"staff_position" => 4, "instrument" => "snare_drum"})
      expect(mapping.position_index).to eq(4)
    end
  end

  describe "#to_s" do
    context "with instrument only" do
      it "returns instrument name and position" do
        mapping = described_class.new({"staff_position" => 4, "instrument" => "snare_drum"})
        expect(mapping.to_s).to eq("snare drum at middle line")
      end
    end

    context "with instrument and playing technique" do
      subject(:mapping) do
        described_class.new({
          "staff_position" => -1,
          "instrument" => "hi_hat",
          "playing_technique" => "pedal"
        })
      end

      its(:to_s) { is_expected.to eq("hi hat (pedal) at space below staff") }
    end

    context "with unknown instrument key" do
      it "uses the instrument_key when instrument lookup fails" do
        mapping = described_class.new({"staff_position" => 4, "instrument" => "unknown_instrument"})
        expect(mapping.to_s).to eq("unknown_instrument at middle line")
      end
    end

    context "without instrument_key" do
      it "omits instrument part" do
        mapping = described_class.new({"staff_position" => 4})
        expect(mapping.to_s).to eq("at middle line")
      end
    end
  end
end
