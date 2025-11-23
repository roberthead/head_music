require "spec_helper"

describe HeadMusic::Content::Bar do
  subject(:bar) { described_class.new(composition) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D major", meter: "6/8") }

  its(:key_signature) { is_expected.to be_nil }
  its(:meter) { is_expected.to be_nil }

  context "when specifying the key signature" do
    subject(:bar) { described_class.new(composition, key_signature: "Bb minor") }

    its(:key_signature) { is_expected.to eq "Bb minor" }
  end

  context "when specifying the meter" do
    subject(:bar) { described_class.new(composition, meter: "5/4") }

    its(:meter) { is_expected.to eq "5/4" }
    its(:to_s) { is_expected.to eq "Bar 5/4" }
  end
end
