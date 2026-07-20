require "spec_helper"

describe HeadMusic::Rudiment::Meter do
  describe ".get" do
    context "when given an instance" do
      let(:instance) { described_class.get("5/4") }

      it "returns that instance" do
        expect(described_class.get(instance)).to be instance
      end
    end

    context "given 3/4" do
      subject(:meter) { described_class.get("3/4") }

      it { is_expected.to be_simple }
      it { is_expected.not_to be_compound }

      it { is_expected.not_to be_duple }
      it { is_expected.to be_triple }
      it { is_expected.not_to be_quadruple }

      its(:beats_per_bar) { are_expected.to eq 3 }
      its(:counts_per_bar) { are_expected.to eq 3 }
      its(:beat_value) { is_expected.to eq :quarter }
      its(:strong_counts) { are_expected.to eq [1] }
      its(:ticks_per_count) { are_expected.to eq 960 }
    end

    context "given 6/8" do
      subject(:meter) { described_class.get("6/8") }

      it { is_expected.not_to be_simple }
      it { is_expected.to be_compound }

      it { is_expected.not_to be_duple }
      it { is_expected.to be_triple }
      it { is_expected.not_to be_quadruple }

      its(:beats_per_bar) { are_expected.to eq 2 }
      its(:counts_per_bar) { are_expected.to eq 6 }
      its(:beat_value) { is_expected.to eq "dotted quarter" }
      its(:strong_counts) { are_expected.to eq [1, 4] }
      its(:ticks_per_count) { are_expected.to eq 480 }
    end

    context "given 9/8" do
      subject(:meter) { described_class.get("9/8") }

      it { is_expected.not_to be_simple }
      it { is_expected.to be_compound }

      it { is_expected.not_to be_duple }
      it { is_expected.to be_triple }
      it { is_expected.not_to be_quadruple }

      its(:beats_per_bar) { are_expected.to eq 3 }
      its(:counts_per_bar) { are_expected.to eq 9 }
      its(:beat_value) { is_expected.to eq "dotted quarter" }
      its(:strong_counts) { are_expected.to eq [1, 4, 7] }
      its(:ticks_per_count) { are_expected.to eq 480 }
    end

    context "given :common_time" do
      subject(:meter) { described_class.get(:common_time) }

      it { is_expected.to be_simple }
      it { is_expected.not_to be_compound }

      it { is_expected.not_to be_duple }
      it { is_expected.not_to be_triple }
      it { is_expected.to be_quadruple }

      its(:beats_per_bar) { are_expected.to eq 4 }
      its(:counts_per_bar) { are_expected.to eq 4 }
      its(:beat_value) { is_expected.to eq "quarter" }
      its(:strong_counts) { are_expected.to eq [1, 3] }
      its(:ticks_per_count) { are_expected.to eq 960 }
    end

    context "given :cut_time" do
      subject(:meter) { described_class.get(:cut_time) }

      it { is_expected.to be_simple }
      it { is_expected.not_to be_compound }

      it { is_expected.to be_duple }
      it { is_expected.not_to be_triple }
      it { is_expected.not_to be_quadruple }

      its(:beats_per_bar) { are_expected.to eq 2 }
      its(:counts_per_bar) { are_expected.to eq 2 }
      its(:beat_value) { is_expected.to eq :half }
      its(:strong_counts) { are_expected.to eq [1, 2] }
      its(:ticks_per_count) { are_expected.to eq 1920 }
    end
  end

  describe "#beat_strength" do
    context "for 6/8" do
      subject(:meter) { described_class.get("6/8") }

      specify { expect(meter.beat_strength(1)).to be > meter.beat_strength(4) }
      specify { expect(meter.beat_strength(4)).to be > meter.beat_strength(3) }
      specify { expect(meter.beat_strength(3)).to eq meter.beat_strength(5) }
      specify { expect(meter.beat_strength(3)).to eq meter.beat_strength(2) }
      specify { expect(meter.beat_strength(3)).to be > meter.beat_strength(1, tick: 240) }
      specify { expect(meter.beat_strength(1, tick: 240)).to be > meter.beat_strength(1, tick: 270) }
    end
  end

  describe "#beam_group_unit" do
    {
      "4/4" => "quarter",
      "3/4" => "quarter",
      "2/4" => "quarter",
      "2/2" => "half",
      "3/8" => "dotted quarter",
      "2/8" => "quarter",
      "6/8" => "dotted quarter",
      "9/8" => "dotted quarter",
      "12/8" => "dotted quarter"
    }.each do |signature, expected|
      context "given #{signature}" do
        subject(:meter) { described_class.get(signature) }

        it "spans #{expected}" do
          expect(meter.beam_group_unit.to_s).to eq expected
        end
      end
    end

    context "given 3/8 (regression: whole bar is one beam group)" do
      subject(:meter) { described_class.get("3/8") }

      it "is a dotted quarter (3 eighths)" do
        expect(meter.beam_group_unit.to_s).to eq "dotted quarter"
        expect(meter.beam_group_unit.total_value).to eq(3 * described_class.get("1/8").beat_value.total_value)
      end

      it "is distinct from beat_value (which is an eighth)" do
        expect(meter.beat_value.to_s).to eq "eighth"
        expect(meter.beam_group_unit).not_to eq meter.beat_value
      end
    end

    context "given 6/8 (regression: compound beat)" do
      subject(:meter) { described_class.get("6/8") }

      it "is a dotted quarter" do
        expect(meter.beam_group_unit.to_s).to eq "dotted quarter"
        expect(meter.beam_group_unit).to eq meter.beat_value
      end
    end

    # Asymmetric meters are out of scope; the group unit must degrade to the
    # count unit rather than raising on a nil (non-power-of-two) unit.
    context "given an asymmetric meter (out of scope, must not raise)" do
      it "falls back to the count unit for 5/16" do
        meter = described_class.get("5/16")
        expect { meter.beam_group_unit }.not_to raise_error
        expect(meter.beam_group_unit).to eq described_class.get("5/16").count_unit
      end

      it "returns a valid rhythmic value for 7/8" do
        expect { described_class.get("7/8").beam_group_unit }.not_to raise_error
      end
    end
  end

  describe "named meter class methods" do
    specify { expect(described_class.common_time).to eq described_class.get("4/4") }
    specify { expect(described_class.cut_time).to eq described_class.get("2/2") }
  end

  describe "#counts_per_quarter_note" do
    context "when given a 4/4 meter" do
      subject(:meter) { described_class.get("4/4") }

      its(:counts_per_quarter_note) { are_expected.to eq 1 }
    end

    context "when given a 6/8 meter" do
      subject(:meter) { described_class.get("6/8") }

      its(:counts_per_quarter_note) { are_expected.to eq 2 }
    end

    context "when given cut time" do
      subject(:meter) { described_class.get(:cut_time) }

      its(:counts_per_quarter_note) { are_expected.to eq 0.5 }
    end
  end

  describe "1/1 meter" do
    subject(:meter) { described_class.get("1/1") }

    its(:counts_per_quarter_note) { are_expected.to eq 0.25 }
  end
end
