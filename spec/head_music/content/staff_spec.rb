require "spec_helper"

describe HeadMusic::Content::Staff do
  subject { described_class.new(:treble_clef) }

  its(:clef) { is_expected.to eq :treble_clef }
  its(:line_count) { is_expected.to be 5 }
  its(:instrument) { is_expected.to be_nil }

  context "when passed an instrument" do
    subject(:staff) { described_class.new(:alto_clef, instrument: :viola) }

    its(:clef) { is_expected.to eq :alto_clef }
    its(:line_count) { is_expected.to be 5 }

    it "has an instrument with name_key :viola" do
      expect(staff.instrument).to be_a(HeadMusic::Instruments::Instrument)
      expect(staff.instrument.name_key).to eq :viola
    end

    context "when default clef is not specified" do
      subject(:foo_clef) { described_class.new("foo", instrument: :viola) }

      its(:clef) { is_expected.to eq :alto_clef }
      its(:line_count) { is_expected.to be 5 }

      it "has an instrument with name_key :viola" do
        expect(foo_clef.instrument).to be_a(HeadMusic::Instruments::Instrument)
        expect(foo_clef.instrument.name_key).to eq :viola
      end

      it "prints a warning" do
        expect { foo_clef }.to output(/Warning: Clef 'foo' not found/).to_stdout
      end
    end
  end

  context "when default clef is not found and no instrument is passed" do
    subject(:foo_clef) { described_class.new("foo") }

    its(:clef) { is_expected.to eq :treble_clef }
    its(:line_count) { is_expected.to be 5 }
    its(:instrument) { is_expected.to be_nil }

    it "prints a warning" do
      expect { foo_clef }.to output(/Warning: Clef 'foo' not found/).to_stdout
    end
  end
end
