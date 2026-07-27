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

      it "recovers from the unrecognized key instead of raising" do
        expect { foo_clef }.not_to raise_error
      end

      # The distinguishing behavior of this branch: an unrecognized key resolves to
      # the instrument's own clef, not to the generic default the no-instrument case
      # falls back to.
      it "prefers the instrument's clef over the generic fallback" do
        expect(foo_clef.clef).not_to eq described_class.new("foo").clef
      end
    end
  end

  context "when default clef is not found and no instrument is passed" do
    subject(:foo_clef) { described_class.new("foo") }

    its(:clef) { is_expected.to eq :treble_clef }
    its(:line_count) { is_expected.to be 5 }
    its(:instrument) { is_expected.to be_nil }

    it "recovers from the unrecognized key instead of raising" do
      expect { foo_clef }.not_to raise_error
    end

    it "builds a usable staff from the fallback" do
      expect(foo_clef.clef).to eq described_class.new(:treble_clef).clef
    end
  end

  context "when the clef key is nil" do
    subject(:nil_clef) { described_class.new(nil) }

    it "recovers instead of raising" do
      expect { nil_clef }.not_to raise_error
    end

    its(:clef) { is_expected.to eq :treble_clef }
  end
end
