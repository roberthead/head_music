require 'spec_helper'

describe HeadMusic::Instrument::StaffScheme do
  subject(:staff_scheme) do
    variant.default_staff_scheme
  end

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

  its(:variant) { is_expected.to eq variant }

  it { is_expected.to be_default }

  its(:staves) { are_expected.to be_an Array }

  its(:staves) { are_expected.not_to be_empty }

  its(:staves) { are_expected.to all be_a HeadMusic::Instrument::Staff }
end
