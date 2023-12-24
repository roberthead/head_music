require "spec_helper"

describe HeadMusic::Instrument::PitchConfiguration do
  subject(:pitch_configuration) do
    described_class.new(:default, clarinet_data)
  end

  let(:clarinet_data) do
    {
      "fundamental_pitch_spelling" => "Bb",
      "staff_configurations" => {
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

  its(:staff_configurations) do
    are_expected.to be_an Array
  end

  its(:staff_configurations) do
    are_expected.not_to be_empty
  end

  its(:default_staff_configuration) do
    is_expected.to be_a HeadMusic::Instrument::StaffConfiguration
  end
end
