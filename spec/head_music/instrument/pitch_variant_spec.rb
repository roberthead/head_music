require "spec_helper"

describe HeadMusic::Instrument::PitchVariant do
  subject(:pitch_variant) do
    described_class.new(:default, clarinet_data)
  end

  let(:clarinet_data) do
    {
      "fundamental_pitch_spelling" => "Bb",
      "staff_schemes" => {
        "default" => [{"clef" => "treble", "sounding_transposition" => -2}]
      }
    }
  end

  it { is_expected.to be_default }

  its(:fundamental_pitch_spelling) do
    is_expected.to be_a HeadMusic::Spelling
  end

  its(:fundamental_pitch_spelling) do
    is_expected.to eq "Bb"
  end

  its(:staff_schemes) do
    are_expected.to be_an Array
  end

  its(:staff_schemes) do
    are_expected.not_to be_empty
  end

  its(:default_staff_scheme) do
    is_expected.to be_a HeadMusic::Instrument::StaffScheme
  end
end
