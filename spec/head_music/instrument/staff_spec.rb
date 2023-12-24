require "spec_helper"

describe HeadMusic::Instrument::Staff do
  subject(:staff) do
    staff_configuration.staves.first
  end

  let(:staff_configuration) do
    pitch_configuration.default_staff_configuration
  end

  let(:pitch_configuration) do
    HeadMusic::Instrument::PitchConfiguration.new(:default, clarinet_data)
  end

  let(:clarinet_data) do
    {
      "fundamental_pitch_spelling" => "Bb",
      "staff_configurations" => {
        "default" => [{"clef" => "treble", "sounding_transposition" => -2}]
      }
    }
  end

  its(:staff_configuration) { is_expected.to eq staff_configuration }

  its(:clef) { is_expected.to eq "treble_clef" }

  its(:sounding_transposition) { is_expected.to eq(-2) }
end
