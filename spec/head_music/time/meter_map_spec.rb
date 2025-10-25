require "spec_helper"

describe HeadMusic::Time::MeterMap do
  describe "#initialize" do
    context "with default starting meter" do
      subject(:meter_map) { described_class.new }

      it "creates a default meter event at 1:1:0:0" do
        events = meter_map.events
        expect(events.length).to eq 1
        expect(events.first.position.to_s).to eq "1:1:0:0"
        expect(events.first.meter.to_s).to eq "4/4"
      end
    end

    context "with custom starting meter" do
      subject(:meter_map) { described_class.new(starting_meter: starting_meter) }

      let(:starting_meter) { HeadMusic::Rudiment::Meter.get("3/4") }

      it "uses the provided meter" do
        expect(meter_map.events.first.meter.to_s).to eq "3/4"
      end
    end

    context "with custom starting position" do
      subject(:meter_map) { described_class.new(starting_position: position) }

      let(:position) { HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0) }

      it "places the first event at the specified position" do
        expect(meter_map.events.first.position.bar).to eq 5
      end
    end
  end

  describe "#add_change" do
    subject(:meter_map) { described_class.new }

    it "adds a meter change at the specified position" do
      position = HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0)
      meter_map.add_change(position, "3/4")

      expect(meter_map.events.length).to eq 2
      expect(meter_map.events.last.position.bar).to eq 5
      expect(meter_map.events.last.meter.to_s).to eq "3/4"
    end

    it "maintains sorted order by position" do
      meter_map.add_change(HeadMusic::Time::MusicalPosition.new(9, 1, 0, 0), "6/8")
      meter_map.add_change(HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0), "3/4")
      meter_map.add_change(HeadMusic::Time::MusicalPosition.new(13, 1, 0, 0), "5/4")

      bars = meter_map.events.map { |e| e.position.bar }
      expect(bars).to eq [1, 5, 9, 13]
    end

    it "accepts a Meter object directly" do
      position = HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0)
      meter = HeadMusic::Rudiment::Meter.get("6/8")
      meter_map.add_change(position, meter)

      expect(meter_map.events.last.meter).to eq meter
    end

    it "replaces an event at the same position" do
      position = HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0)
      meter_map.add_change(position, "3/4")
      meter_map.add_change(position, "5/4")
      events_at_bar_5 = meter_map.events.select { |e| e.position.bar == 5 }
      expect(events_at_bar_5).to contain_exactly(have_attributes(meter: have_attributes(to_s: "5/4")))
    end
  end

  describe "#meter_at" do
    subject(:meter_map) { described_class.new }

    before do
      meter_map.add_change(HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0), "3/4")
      meter_map.add_change(HeadMusic::Time::MusicalPosition.new(9, 1, 0, 0), "6/8")
    end

    it "returns the starting meter before any changes" do
      position = HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0)
      meter = meter_map.meter_at(position)
      expect(meter.to_s).to eq "4/4"
    end

    it "returns the correct meter after the first change" do
      position = HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0)
      meter = meter_map.meter_at(position)
      expect(meter.to_s).to eq "3/4"
    end

    it "returns the correct meter between changes" do
      position = HeadMusic::Time::MusicalPosition.new(7, 1, 0, 0)
      meter = meter_map.meter_at(position)
      expect(meter.to_s).to eq "3/4"
    end

    it "returns the correct meter after the second change" do
      position = HeadMusic::Time::MusicalPosition.new(10, 1, 0, 0)
      meter = meter_map.meter_at(position)
      expect(meter.to_s).to eq "6/8"
    end

    it "handles positions with ticks" do
      position = HeadMusic::Time::MusicalPosition.new(5, 1, 480, 0)
      meter = meter_map.meter_at(position)
      expect(meter.to_s).to eq "3/4"
    end
  end

  describe "#each_segment" do
    subject(:meter_map) { described_class.new }

    before do
      meter_map.add_change(HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0), "3/4")
      meter_map.add_change(HeadMusic::Time::MusicalPosition.new(9, 1, 0, 0), "6/8")
    end

    def collect_meter_segments(from, to)
      segments = []
      meter_map.each_segment(from, to) { |start_pos, end_pos, meter| segments << [start_pos.bar, end_pos.bar, meter.to_s] }
      segments
    end

    it "yields segments with start, end, and meter" do
      from = HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0)
      to = HeadMusic::Time::MusicalPosition.new(10, 1, 0, 0)
      expect(collect_meter_segments(from, to)).to eq [[1, 5, "4/4"], [5, 9, "3/4"], [9, 10, "6/8"]]
    end

    it "handles a range within a single meter" do
      from = HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0)
      to = HeadMusic::Time::MusicalPosition.new(3, 1, 0, 0)
      expect(collect_meter_segments(from, to)).to eq [[1, 3, "4/4"]]
    end

    it "handles a range starting after meter changes" do
      from = HeadMusic::Time::MusicalPosition.new(9, 1, 0, 0)
      to = HeadMusic::Time::MusicalPosition.new(15, 1, 0, 0)
      expect(collect_meter_segments(from, to)).to eq [[9, 15, "6/8"]]
    end

    it "handles positions with ticks" do
      from = HeadMusic::Time::MusicalPosition.new(4, 1, 480, 0)
      to = HeadMusic::Time::MusicalPosition.new(5, 1, 480, 0)
      segments = []
      meter_map.each_segment(from, to) { |s, e, m| segments << {start: s.to_s, end: e.to_s, meter: m.to_s} }
      expect(segments).to contain_exactly(hash_including(meter: "4/4"), hash_including(meter: "3/4"))
    end
  end

  describe "#remove_change" do
    subject(:meter_map) { described_class.new }

    before do
      meter_map.add_change(HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0), "3/4")
      meter_map.add_change(HeadMusic::Time::MusicalPosition.new(9, 1, 0, 0), "6/8")
    end

    it "removes a meter change at the specified position" do
      position = HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0)
      meter_map.remove_change(position)

      expect(meter_map.events.length).to eq 2
      expect(meter_map.events.map { |e| e.position.bar }).to eq [1, 9]
    end

    it "does not remove the starting meter" do
      position = HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0)
      meter_map.remove_change(position)

      expect(meter_map.events.length).to eq 3
      expect(meter_map.events.first.position.bar).to eq 1
    end
  end

  describe "#clear_changes" do
    subject(:meter_map) { described_class.new }

    before do
      meter_map.add_change(HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0), "3/4")
      meter_map.add_change(HeadMusic::Time::MusicalPosition.new(9, 1, 0, 0), "6/8")
    end

    it "removes all changes except the starting meter" do
      meter_map.clear_changes

      expect(meter_map.events.length).to eq 1
      expect(meter_map.events.first.position.bar).to eq 1
    end
  end
end
