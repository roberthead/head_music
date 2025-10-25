require "spec_helper"

describe HeadMusic::Time::MeterEvent do
  describe "#initialize" do
    subject(:event) { described_class.new(position, meter) }

    let(:position) { HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0) }
    let(:meter) { HeadMusic::Rudiment::Meter.get("4/4") }

    its(:position) { is_expected.to eq position }
    its(:meter) { is_expected.to eq meter }

    context "with different meter" do
      let(:meter) { HeadMusic::Rudiment::Meter.get("3/4") }

      its(:meter) { is_expected.to eq meter }
    end

    context "with different position" do
      let(:position) { HeadMusic::Time::MusicalPosition.new(5, 3, 480, 0) }

      its(:position) { is_expected.to eq position }
    end

    context "with string meter identifier" do
      let(:meter) { "6/8" }

      it "accepts a meter identifier" do
        expect(event.meter).to eq "6/8"
      end
    end
  end

  describe "position modification" do
    subject(:event) { described_class.new(position, meter) }

    let(:position) { HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0) }
    let(:meter) { HeadMusic::Rudiment::Meter.get("4/4") }

    it "allows position to be updated" do
      new_position = HeadMusic::Time::MusicalPosition.new(2, 1, 0, 0)
      event.position = new_position
      expect(event.position).to eq new_position
    end
  end

  describe "meter modification" do
    subject(:event) { described_class.new(position, meter) }

    let(:position) { HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0) }
    let(:meter) { HeadMusic::Rudiment::Meter.get("4/4") }

    it "allows meter to be updated" do
      new_meter = HeadMusic::Rudiment::Meter.get("3/4")
      event.meter = new_meter
      expect(event.meter).to eq new_meter
    end
  end
end
