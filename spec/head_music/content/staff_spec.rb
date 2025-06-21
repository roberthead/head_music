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

    context "when default clef is not specified" do
      subject { described_class.new('foo', instrument: :viola) }

      its(:clef) { is_expected.to eq :alto_clef }
      its(:line_count) { is_expected.to be 5 }
      its(:instrument) { is_expected.to eq :viola }

      it "prints a warning" do
        expect { subject }.to output(/Warning: Clef 'foo' not found/).to_stdout
      end
    end
  end

  context "when default clef is not found and no instrument is passed" do
    subject { described_class.new('foo') }

    its(:clef) { is_expected.to eq :treble_clef }
    its(:line_count) { is_expected.to be 5 }
    its(:instrument) { is_expected.to be_nil }

    it "prints a warning" do
      expect { subject }.to output(/Warning: Clef 'foo' not found/).to_stdout
    end
  end
end
