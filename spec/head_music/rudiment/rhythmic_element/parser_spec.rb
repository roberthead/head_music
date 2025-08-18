require "spec_helper"

describe HeadMusic::Rudiment::RhythmicElement::Parser do
  subject(:parser) { described_class.new(input_string) }

  context "with a pitch string" do
    let(:input_string) { "F#4 dotted-quarter" }

    its(:identifier) { is_expected.to eq("F#4 dotted-quarter") }
    its(:letter_name) { is_expected.to eq("F") }
    its(:alteration) { is_expected.to eq("sharp") }
    its(:register) { is_expected.to eq(4) }
    its(:rhythmic_value) { is_expected.to eq("dotted quarter") }
    its(:parsed_element) { is_expected.to be_a(HeadMusic::Rudiment::Note) }
  end

  context "with a rest string" do
    let(:input_string) { "quarter rest" }

    its(:identifier) { is_expected.to eq("quarter rest") }
    its(:letter_name) { is_expected.to be_nil }
    its(:alteration) { is_expected.to be_nil }
    its(:register) { is_expected.to be_nil }
    its(:rhythmic_value) { is_expected.to eq("quarter") }
    its(:parsed_element) { is_expected.to be_a(HeadMusic::Rudiment::Rest) }
  end

  context "with a meaningless string" do
    let(:input_string) { "jabberwocky" }

    its(:identifier) { is_expected.to eq("jabberwocky") }
    its(:letter_name) { is_expected.to be_nil }
    its(:alteration) { is_expected.to be_nil }
    its(:register) { is_expected.to be_nil }
    its(:rhythmic_value) { is_expected.to be_nil }
    its(:parsed_element) { is_expected.to be_nil }
  end
end
