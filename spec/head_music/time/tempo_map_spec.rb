require "spec_helper"

describe HeadMusic::Time::TempoMap do
  describe "#initialize" do
    context "with default starting tempo" do
      subject(:tempo_map) { described_class.new }

      it "creates a default tempo event at 1:1:0:0" do
        events = tempo_map.events
        expect(events.length).to eq 1
        expect(events.first.position.to_s).to eq "1:1:0:0"
        expect(events.first.tempo.beats_per_minute).to eq 120.0
      end
    end

    context "with custom starting tempo" do
      subject(:tempo_map) { described_class.new(starting_tempo: starting_tempo) }

      let(:starting_tempo) { HeadMusic::Rudiment::Tempo.new("quarter", 96) }

      it "uses the provided tempo" do
        expect(tempo_map.events.first.tempo.beats_per_minute).to eq 96.0
      end
    end

    context "with custom starting position" do
      subject(:tempo_map) { described_class.new(starting_position: position) }

      let(:position) { HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0) }

      it "places the first event at the specified position" do
        expect(tempo_map.events.first.position.bar).to eq 5
      end
    end
  end

  describe "#add_change" do
    subject(:tempo_map) { described_class.new }

    it "adds a tempo change at the specified position" do
      position = HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0)
      tempo_map.add_change(position, "quarter", 140)

      expect(tempo_map.events.length).to eq 2
      expect(tempo_map.events.last.position.bar).to eq 5
      expect(tempo_map.events.last.tempo.beats_per_minute).to eq 140.0
    end

    it "maintains sorted order by position" do
      tempo_map.add_change(HeadMusic::Time::MusicalPosition.new(9, 1, 0, 0), "quarter", 140)
      tempo_map.add_change(HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0), "quarter", 96)
      tempo_map.add_change(HeadMusic::Time::MusicalPosition.new(13, 1, 0, 0), "quarter", 120)

      bars = tempo_map.events.map { |e| e.position.bar }
      expect(bars).to eq [1, 5, 9, 13]
    end

    it "accepts a Tempo object directly" do
      position = HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0)
      tempo = HeadMusic::Rudiment::Tempo.new("eighth", 200)
      tempo_map.add_change(position, tempo)

      expect(tempo_map.events.last.tempo).to eq tempo
    end

    it "replaces an event at the same position" do
      position = HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0)
      tempo_map.add_change(position, "quarter", 96)
      tempo_map.add_change(position, "quarter", 140)
      events_at_bar_5 = tempo_map.events.select { |e| e.position.bar == 5 }
      expect(events_at_bar_5).to contain_exactly(have_attributes(tempo: have_attributes(beats_per_minute: 140.0)))
    end
  end

  describe "#tempo_at" do
    subject(:tempo_map) { described_class.new }

    before do
      tempo_map.add_change(HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0), "quarter", 96)
      tempo_map.add_change(HeadMusic::Time::MusicalPosition.new(9, 1, 0, 0), "quarter", 140)
    end

    it "returns the starting tempo before any changes" do
      position = HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0)
      tempo = tempo_map.tempo_at(position)
      expect(tempo.beats_per_minute).to eq 120.0
    end

    it "returns the correct tempo after the first change" do
      position = HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0)
      tempo = tempo_map.tempo_at(position)
      expect(tempo.beats_per_minute).to eq 96.0
    end

    it "returns the correct tempo between changes" do
      position = HeadMusic::Time::MusicalPosition.new(7, 1, 0, 0)
      tempo = tempo_map.tempo_at(position)
      expect(tempo.beats_per_minute).to eq 96.0
    end

    it "returns the correct tempo after the second change" do
      position = HeadMusic::Time::MusicalPosition.new(10, 1, 0, 0)
      tempo = tempo_map.tempo_at(position)
      expect(tempo.beats_per_minute).to eq 140.0
    end

    it "handles positions with ticks" do
      position = HeadMusic::Time::MusicalPosition.new(5, 1, 480, 0)
      tempo = tempo_map.tempo_at(position)
      expect(tempo.beats_per_minute).to eq 96.0
    end
  end

  describe "#each_segment" do
    subject(:tempo_map) { described_class.new }

    before do
      tempo_map.add_change(HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0), "quarter", 96)
      tempo_map.add_change(HeadMusic::Time::MusicalPosition.new(9, 1, 0, 0), "quarter", 140)
    end

    def collect_tempo_segments(from, to)
      segments = []
      tempo_map.each_segment(from, to) { |start_pos, end_pos, tempo| segments << [start_pos.bar, end_pos.bar, tempo.beats_per_minute] }
      segments
    end

    it "yields segments with start, end, and tempo" do
      from = HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0)
      to = HeadMusic::Time::MusicalPosition.new(10, 1, 0, 0)
      expect(collect_tempo_segments(from, to)).to eq [[1, 5, 120.0], [5, 9, 96.0], [9, 10, 140.0]]
    end

    it "handles a range within a single tempo" do
      from = HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0)
      to = HeadMusic::Time::MusicalPosition.new(3, 1, 0, 0)
      expect(collect_tempo_segments(from, to)).to eq [[1, 3, 120.0]]
    end

    it "handles a range starting after tempo changes" do
      from = HeadMusic::Time::MusicalPosition.new(9, 1, 0, 0)
      to = HeadMusic::Time::MusicalPosition.new(15, 1, 0, 0)
      expect(collect_tempo_segments(from, to)).to eq [[9, 15, 140.0]]
    end

    it "handles positions with ticks" do
      from = HeadMusic::Time::MusicalPosition.new(4, 1, 480, 0)
      to = HeadMusic::Time::MusicalPosition.new(5, 1, 480, 0)
      segments = []
      tempo_map.each_segment(from, to) { |s, e, t| segments << {start: s.to_s, end: e.to_s, bpm: t.beats_per_minute} }
      expect(segments).to contain_exactly(hash_including(bpm: 120.0), hash_including(bpm: 96.0))
    end
  end

  describe "#remove_change" do
    subject(:tempo_map) { described_class.new }

    before do
      tempo_map.add_change(HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0), "quarter", 96)
      tempo_map.add_change(HeadMusic::Time::MusicalPosition.new(9, 1, 0, 0), "quarter", 140)
    end

    it "removes a tempo change at the specified position" do
      position = HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0)
      tempo_map.remove_change(position)

      expect(tempo_map.events.length).to eq 2
      expect(tempo_map.events.map { |e| e.position.bar }).to eq [1, 9]
    end

    it "does not remove the starting tempo" do
      position = HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0)
      tempo_map.remove_change(position)

      expect(tempo_map.events.length).to eq 3
      expect(tempo_map.events.first.position.bar).to eq 1
    end
  end

  describe "#clear_changes" do
    subject(:tempo_map) { described_class.new }

    before do
      tempo_map.add_change(HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0), "quarter", 96)
      tempo_map.add_change(HeadMusic::Time::MusicalPosition.new(9, 1, 0, 0), "quarter", 140)
    end

    it "removes all changes except the starting tempo" do
      tempo_map.clear_changes

      expect(tempo_map.events.length).to eq 1
      expect(tempo_map.events.first.position.bar).to eq 1
    end
  end
end
