require "spec_helper"

describe HeadMusic::Time::MeterScale do
  subject(:scale) { described_class.new(meter_map) }

  let(:meter_map) { HeadMusic::Time::MeterMap.new(starting_meter: "4/4") }
  let(:quarter) { 960 * HeadMusic::Time::SUBTICKS_PER_TICK }

  def position(*components)
    HeadMusic::Time::MusicalPosition.new(*components)
  end

  context "with one meter" do
    it "measures from the first bar's downbeat" do
      expect(scale.subticks_at(position(1, 1, 0, 0))).to eq 0
    end

    it "counts four quarters to a bar" do
      expect(scale.subticks_at(position(3, 2, 0, 0))).to eq 9 * quarter
    end

    it "measures a pickup bar below zero" do
      expect(scale.subticks_at(position(0, 4, 0, 0))).to eq(-quarter)
    end

    it "reads positions back" do
      expect(scale.position_at(9 * quarter + 5).to_a).to eq [3, 2, 0, 5]
    end
  end

  context "with a change to 3/4 at bar 5" do
    before { meter_map.add_change(position(5, 1, 0, 0), "3/4") }

    it "counts the bars before the change in 4/4" do
      expect(scale.subticks_at(position(5, 1, 0, 0))).to eq 16 * quarter
    end

    it "counts the bars after the change in 3/4" do
      expect(scale.subticks_at(position(7, 2, 0, 0))).to eq 23 * quarter
    end

    it "reads positions back in the meter in force" do
      expect(scale.position_at(23 * quarter).to_a).to eq [7, 2, 0, 0]
    end

    it "reads a position just before the change in the earlier meter" do
      expect(scale.position_at(16 * quarter - 1).to_a).to eq [4, 4, 959, 239]
    end
  end
end
