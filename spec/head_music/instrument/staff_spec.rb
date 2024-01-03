require "spec_helper"

describe HeadMusic::Instrument::Staff do
  subject(:staff) do
    staff_scheme.staves.first
  end

  let(:staff_scheme) do
    variant.default_staff_scheme
  end

  context "with clarinet data" do
    let(:variant) do
      HeadMusic::Instrument::Variant.new(:default, clarinet_data)
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
      HeadMusic::Instrument::Variant.new(:default, organ_data)
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
end
