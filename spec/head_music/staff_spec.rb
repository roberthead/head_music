require "spec_helper"

describe HeadMusic::Content::Staff do
  subject { described_class.new(:treble_clef) }

  its(:clef) { is_expected.to eq :treble_clef }
  its(:line_count) { is_expected.to be 5 }
  its(:instrument) { is_expected.to be_nil }

  context "when passed an instrument" do
    subject { described_class.new(:alto_clef, instrument: :viola) }

    its(:clef) { is_expected.to eq :alto_clef }
    its(:line_count) { is_expected.to be 5 }
    its(:instrument) { is_expected.to eq :viola }
  end
end
