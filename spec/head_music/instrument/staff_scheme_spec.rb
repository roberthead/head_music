require 'spec_helper'

describe HeadMusic::Instrument::StaffScheme do
  subject(:staff_scheme) do
    pitch_variant.default_staff_scheme
  end

  let(:pitch_variant) do
    HeadMusic::Instrument::PitchVariant.new(:default, clarinet_data)
  end

  let(:clarinet_data) do
    {
      "fundamental_pitch_spelling" => "Bb",
      "staff_schemes" => {
        "default" => [{"clef" => "treble", "sounding_transposition" => -2}]
      }
    }
  end

  its(:pitch_variant) { is_expected.to eq pitch_variant }

  it { is_expected.to be_default }

  its(:staves) { are_expected.to be_an Array }

  its(:staves) { are_expected.not_to be_empty }

  its(:staves) { are_expected.to all be_a HeadMusic::Instrument::Staff }
end
