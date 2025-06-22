require "spec_helper"

describe HeadMusic::Instruments::Variant do
  context "for clarinet" do
    subject(:variant) do
      described_class.new(:default, clarinet_data)
    end

    let(:clarinet_data) do
      {
        "pitch_designation" => "Bb",
        "staff_schemes" => {
          "default" => [{"clef" => "treble", "sounding_transposition" => -2}]
        }
      }
    end

    it { is_expected.to be_default }

    its(:pitch_designation) do
      is_expected.to be_a HeadMusic::Rudiment::Spelling
    end

    its(:pitch_designation) do
      is_expected.to eq "Bb"
    end

    its(:staff_schemes) do
      are_expected.to be_an Array
    end

    its(:staff_schemes) do
      are_expected.not_to be_empty
    end

    its(:default_staff_scheme) do
      is_expected.to be_a HeadMusic::Instruments::StaffScheme
    end
  end

  context "for alto voice" do
    subject(:variant) do
      described_class.new(:default, alto_voice_data)
    end

    let(:alto_voice_data) do
      {
        "staff_schemes" => {
          "default" => [{"clef" => "treble_clef"}]
        }
      }
    end

    its(:pitch_designation) do
      is_expected.to be_nil
    end
  end
end
