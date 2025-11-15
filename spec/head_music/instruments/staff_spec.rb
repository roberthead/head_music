require "spec_helper"

describe HeadMusic::Instruments::Staff do
  subject(:staff) do
    staff_scheme.staves.first
  end

  let(:staff_scheme) do
    variant.default_staff_scheme
  end

  context "with clarinet data" do
    let(:variant) do
      HeadMusic::Instruments::Variant.new(:default, clarinet_data)
    end

    let(:clarinet_data) do
      {
        "pitch_designation" => "Bb",
        "staff_schemes" => {
          "default" => [{"clef" => "treble", "sounding_transposition" => -2}]
        }
      }
    end

    its(:staff_scheme) { is_expected.to eq staff_scheme }

    its(:clef) { is_expected.to eq "treble_clef" }
    its(:name_key) { is_expected.to eq "" }
    its(:name) { is_expected.to eq "" }
    its(:sounding_transposition) { is_expected.to eq(-2) }
  end

  context "with organ data" do
    let(:variant) do
      HeadMusic::Instruments::Variant.new(:default, organ_data)
    end

    let(:organ_data) do
      {
        "pitch_designation" => "Bb",
        "staff_schemes" => {
          "default" => [
            {"clef" => "treble_clef", "name_key" => "right_hand"},
            {"clef" => "bass_clef", "name_key" => "left_hand"},
            {"clef" => "bass_clef", "name_key" => "pedalboard"}
          ]
        }
      }
    end

    its(:staff_scheme) { is_expected.to eq staff_scheme }

    its(:clef) { is_expected.to eq "treble_clef" }
    its(:name_key) { is_expected.to eq "right_hand" }
    its(:name) { is_expected.to eq "right hand" }
    its(:sounding_transposition) { is_expected.to eq(0) }
  end

  context "with drum_kit data (staff mappings)" do
    let(:variant) do
      HeadMusic::Instruments::Variant.new(:default, drum_kit_data)
    end

    let(:drum_kit_data) do
      {
        "staff_schemes" => {
          "default" => [
            {
              "clef" => "neutral_clef",
              "mappings" => [
                {"staff_position" => -1, "instrument" => "hi_hat", "playing_technique" => "pedal"},
                {"staff_position" => 0, "instrument" => "bass_drum"},
                {"staff_position" => 2, "instrument" => "floor_tom"},
                {"staff_position" => 4, "instrument" => "snare_drum"},
                {"staff_position" => 6, "instrument" => "mid_tom"},
                {"staff_position" => 7, "instrument" => "high_tom"},
                {"staff_position" => 8, "instrument" => "ride_cymbal"},
                {"staff_position" => 9, "instrument" => "hi_hat", "playing_technique" => "stick"},
                {"staff_position" => 10, "instrument" => "crash_cymbal"}
              ]
            }
          ]
        }
      }
    end

    its(:clef) { is_expected.to eq "neutral_clef" }

    describe "#mappings" do
      it "returns an array of StaffMapping objects" do
        expect(staff.mappings).to be_an(Array)
        expect(staff.mappings).to all(be_a(HeadMusic::Instruments::StaffMapping))
        expect(staff.mappings.length).to eq(9)
      end
    end

    describe "#mapping_for_position" do
      it "returns the mapping at a given position index" do
        mapping = staff.mapping_for_position(4)
        expect(mapping).to be_a(HeadMusic::Instruments::StaffMapping)
        expect(mapping.instrument_key).to eq("snare_drum")
      end

      it "returns nil for unmapped positions" do
        expect(staff.mapping_for_position(1)).to be_nil
      end
    end

    describe "#instrument_for_position" do
      it "returns the instrument at a given position index" do
        instrument = staff.instrument_for_position(4)
        expect(instrument).to be_a(HeadMusic::Instruments::Instrument)
        expect(instrument.name).to eq("snare drum")
      end

      it "returns nil for unmapped positions" do
        expect(staff.instrument_for_position(1)).to be_nil
      end
    end

    describe "#positions_for_instrument" do
      it "returns all positions for a given instrument" do
        positions = staff.positions_for_instrument("hi_hat")
        expect(positions).to be_an(Array)
        expect(positions.length).to eq(2)
        expect(positions).to contain_exactly(-1, 9)
      end

      it "returns single position for instruments with one mapping" do
        positions = staff.positions_for_instrument("snare_drum")
        expect(positions).to eq([4])
      end

      it "returns empty array for instruments not in the mapping" do
        expect(staff.positions_for_instrument("triangle")).to eq([])
      end
    end

    describe "#components" do
      it "returns array of unique instruments in the mapping" do
        components = staff.components
        expect(components).to be_an(Array)
        expect(components.length).to eq(8)
        expect(components).to all(be_a(HeadMusic::Instruments::Instrument))
      end

      it "returns unique instruments even if mapped to multiple positions" do
        component_names = staff.components.map(&:name)
        expect(component_names).to contain_exactly("bass drum", "floor tom", "snare drum", "mid tom", "high tom", "ride cymbal", "hi hat", "crash cymbal")
      end
    end
  end

  context "without staff mappings" do
    let(:variant) do
      HeadMusic::Instruments::Variant.new(:default, simple_data)
    end

    let(:simple_data) do
      {
        "staff_schemes" => {
          "default" => [{"clef" => "treble_clef"}]
        }
      }
    end

    describe "#mappings" do
      it "returns empty array when no mappings defined" do
        expect(staff.mappings).to eq([])
      end
    end

    describe "#components" do
      it "returns empty array when no mappings defined" do
        expect(staff.components).to eq([])
      end
    end
  end
end
