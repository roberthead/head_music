require "spec_helper"

describe HeadMusic::MIDI::PartReading do
  let(:layout) do
    time_signatures = [HeadMusic::MIDI::TimeSignature.new(0, 1, 4, 24), HeadMusic::MIDI::TimeSignature.new(96, 3, 4, 24)]
    HeadMusic::MIDI::BarLayout.new(time_signatures, division: 96, end_tick: 96 + 288 * 2)
  end

  describe ".measures" do
    it "gives each bar as a measure, a pickup implicit, each as long as its bar" do
      expect(described_class.measures(layout).map { |measure| [measure.index, measure.implicit, measure.extent, measure.meter.to_s, measure.tolerance] }).to eq [
        [0, true, Rational(1, 4), "3/4", 0], [1, false, Rational(3, 4), "3/4", 0], [2, false, Rational(3, 4), "3/4", 0]
      ]
    end
  end

  describe "#tracks" do
    subject(:reading) do
      described_class.new(described_class.measures(layout), layout: layout, values: HeadMusic::MIDI::NoteValues.new(layout), voices: [[[Rational(1, 4), Rational(1, 2), ["C4"]]]], label: "track 1")
    end

    it "writes the rests between notes, a whole bar's as filling its bar" do
      expect(reading.tracks.first.events.map { |event| [event.measure_index, event.cursor, event.rhythmic_value.to_s, event.sounds, event.fills_bar] }).to eq [
        [0, 0, "quarter", [], true], [1, 0, "quarter", ["C4"], false], [1, Rational(1, 4), "quarter", [], false], [1, Rational(1, 2), "quarter", [], false],
        [2, 0, "dotted half", [], true]
      ]
    end

    it "labels each voice" do
      expect(reading.tracks.map(&:label)).to eq ["track 1, voice 1"]
    end
  end

  it "raises the MIDI errors, naming no place in the file" do
    reading = described_class.new([])
    expect([reading.errors, reading.where(3)]).to eq [HeadMusic::MIDI, {}]
  end
end
