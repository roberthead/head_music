# frozen_string_literal: true

require "spec_helper"

describe HeadMusic::Position do
  subject(:position) { described_class.new(composition, bar_number, count, tick) }

  let(:composition) { HeadMusic::Composition.new }
  let(:bar_number) { 3 }
  let(:count) { 2 }
  let(:tick) { 480 }

  its(:composition) { is_expected.to eq composition }
  its(:bar_number) { is_expected.to eq 3 }
  its(:count) { is_expected.to eq 2 }
  its(:tick) { is_expected.to eq 480 }
  its(:to_s) { is_expected.to eq "3:2:480" }
  its(:start_of_next_bar) { is_expected.to eq "4:1:000" }

  context "when there are a small number of ticks" do
    let(:tick) { 60 }

    its(:code) { is_expected.to eq "3:2:060" }
  end

  context "when there are no ticks" do
    let(:tick) { 0 }

    its(:code) { is_expected.to eq "3:2:000" }
  end

  describe "#strength" do
    context "for the downbeat" do
      let(:count) { 1 }
      let(:tick) { 0 }

      its(:strength) { is_expected.to eq 100 }
      it { is_expected.to be_strong }
      it { is_expected.not_to be_weak }
    end

    context "for the middle beat" do
      let(:count) { 3 }
      let(:tick) { 0 }

      its(:strength) { is_expected.to eq 80 }
      it { is_expected.to be_strong }
      it { is_expected.not_to be_weak }
    end

    context "for an off-beat" do
      let(:count) { 4 }
      let(:tick) { 0 }

      its(:strength) { is_expected.to eq 60 }
      it { is_expected.not_to be_strong }
      it { is_expected.to be_weak }
    end

    context "for a division" do
      let(:count) { 1 }
      let(:tick) { HeadMusic::RhythmicUnit.get(:eighth).ticks }

      its(:strength) { is_expected.to eq 40 }
      it { is_expected.not_to be_strong }
      it { is_expected.to be_weak }
    end

    context "for a division" do
      let(:count) { 1 }
      let(:tick) { HeadMusic::RhythmicUnit.get("thirty-second").ticks }

      its(:strength) { is_expected.to eq 20 }
      it { is_expected.not_to be_strong }
      it { is_expected.to be_weak }
    end
  end

  describe "value rollover" do
    context "in 4/4" do
      context "given too many ticks" do
        let(:bar_number) { 3 }
        let(:count) { 2 }
        let(:tick) { 1000 }

        it "rolls over to the next count" do
          expect(position).to eq described_class.new(composition, 3, 3, 40)
        end
      end

      context "given exactly one beat worth of ticks" do
        let(:bar_number) { 3 }
        let(:count) { 2 }
        let(:tick) { 960 }

        it "rolls over to the next count" do
          expect(position).to eq "3:3:000"
        end
      end

      context "given too many counts" do
        let(:bar_number) { 3 }
        let(:count) { 9 }
        let(:tick) { 0 }

        it "rolls over to a subsequent bar" do
          expect(position).to eq described_class.new(composition, "5:1:0")
        end
      end
    end

    context "in 6/8" do
      let(:composition) { HeadMusic::Composition.new(meter: "6/8") }

      context "given too many ticks" do
        let(:bar_number) { 3 }
        let(:count) { 4 }
        let(:tick) { 720 }

        it "rolls over to a subsequent count" do
          expect(composition.meter).to eq "6/8"
          expect(position.meter).to eq "6/8"
          expect(position).to eq described_class.new(composition, 3, 5, 240)
        end
      end

      context "given too many counts" do
        let(:bar_number) { 3 }
        let(:count) { 9 }
        let(:tick) { 0 }

        it "rolls over to a subsequent bar" do
          expect(position).to eq described_class.new(composition, "4:3:0")
        end
      end
    end
  end

  describe "addition" do
    context "when adding a rhythmic unit" do
      context "within a bar" do
        let(:expected_position) { described_class.new(composition, bar_number, count + 1, tick) }

        specify { expect(position + HeadMusic::RhythmicUnit.get(:quarter)).to eq expected_position }
      end

      context "across a bar" do
        let(:expected_position) { described_class.new(composition, bar_number + 1, count, tick) }

        specify { expect(position + HeadMusic::RhythmicUnit.get(:whole)).to eq expected_position }
      end
    end

    context "when adding a rhythmic value" do
      context "within a bar" do
        let(:expected_position) { described_class.new(composition, "3.4.480") }

        specify { expect(position + HeadMusic::RhythmicValue.new(:half)).to eq expected_position }
      end

      context "across a bar" do
        let(:expected_position) { described_class.new(composition, "4.1.480") }

        specify { expect(HeadMusic::RhythmicValue.new(:half, dots: 1).relative_value).to eq 0.75 }
        specify { expect(HeadMusic::RhythmicValue.new(:half, dots: 1).ticks).to eq 960 * 3 }

        specify { expect(position + HeadMusic::RhythmicValue.new(:half, dots: 1)).to eq expected_position }
      end
    end
  end

  describe "comparison" do
    context "when the bars are unequal" do
      let(:position1) { described_class.new(composition, 1, 4, tick) }
      let(:position2) { described_class.new(composition, 2, 1, tick) }

      specify { expect(position1).to be < position2 }
      specify { expect([position2, position1].sort).to eq [position1, position2] }
    end

    context "when the bars are equal" do
      context "when the counts are unequal" do
        let(:position1) { described_class.new(composition, bar_number, 3, 0) }
        let(:position2) { described_class.new(composition, bar_number, 2, 120) }

        specify { expect(position1).to be > position2 }
        specify { expect([position1, position2].sort).to eq [position2, position1] }
      end

      context "when the counts are equal" do
        context "when the ticks are unequal" do
          let(:position1) { described_class.new(composition, bar_number, count, 0) }
          let(:position2) { described_class.new(composition, bar_number, count, 120) }

          specify { expect(position1).to be < position2 }
          specify { expect([position2, position1].sort).to eq [position1, position2] }
        end

        context "when the ticks are equal" do
          let(:position1) { described_class.new(composition, bar_number, count, tick) }
          let(:position2) { described_class.new(composition, bar_number, count, tick) }

          specify { expect(position1).to be == position2 }
        end
      end
    end
  end

  describe "#within_placement?" do
    let(:voice) { composition.add_voice }
    let!(:placement) { HeadMusic::Placement.new(voice, "3:2:000", :quarter) }

    context "when the position is before the start of the placement" do
      subject(:position) { described_class.new(composition, 3, 1, 0) }

      it { is_expected.not_to be_within_placement(placement) }
    end

    context "when the position is at the start of the placement" do
      subject(:position) { described_class.new(composition, 3, 2, 0) }

      it { is_expected.to be_within_placement(placement) }
    end

    context "when the position is after the start of the placement" do
      context "and before the end of the placement" do
        subject(:position) { described_class.new(composition, 3, 2, 240) }

        it { is_expected.to be_within_placement(placement) }
      end

      context "and at the end of the placement" do
        subject(:position) { described_class.new(composition, 3, 3, 0) }

        it { is_expected.not_to be_within_placement(placement) }
      end

      context "and after the end of the placement" do
        subject(:position) { described_class.new(composition, 3, 4, 0) }

        it { is_expected.not_to be_within_placement(placement) }
      end
    end
  end
end
