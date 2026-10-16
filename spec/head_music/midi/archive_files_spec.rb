require "spec_helper"

# Sequenced files from archives, read end to end. See
# spec/fixtures/midi/README.md for their sources and licenses.
describe "HeadMusic::MIDI" do
  fixture_directory = File.expand_path("../../fixtures/midi", __dir__)

  def grid(bytes)
    sequence = HeadMusic::MIDI::Reader.new(bytes).read
    budget = HeadMusic::MIDI::Budget.new(sequence)
    layout = HeadMusic::MIDI::BarLayout.new(budget.time_signatures, division: sequence.division, end_tick: budget.end_tick)
    HeadMusic::MIDI::Quantizer.new(layout, sequence.notes, division: sequence.division).grid
  end

  def summary(flow)
    {
      parts: flow.parts.map { |part| [part.player&.name, part.instrument&.name_key, part.voices.length] },
      meter: flow.meter.to_s, meter_changes: flow.meter_changes.length,
      key: flow.timeline.tonal_context_at(flow.earliest_bar_number).name,
      bars: [flow.earliest_bar_number, flow.last_sounding_bar_number],
      notes: HeadMusic::Analysis::NoteInput.for(flow).notes.length
    }
  end

  describe "Mutopia's Polonaise in F major, BWV Anh. 117a" do
    let(:bytes) { File.binread(File.join(fixture_directory, "mutopia", "BWV-117a.mid")) }
    let(:flow) { HeadMusic::MIDI.parse(bytes) }

    it "reads two staves of two voices each in 3/4 and F major, on a sixteenth grid" do
      expect([summary(flow), grid(bytes)]).to eq [{
        parts: [["upper", nil, 2], ["lower", nil, 2]], meter: "3/4", meter_changes: 0,
        key: "F major", bars: [1, 16], notes: 235
      }, Rational(1, 16)]
    end

    it "leaves no gap in any voice" do
      expect(flow.voices.map(&:first_gap)).to all(be_nil)
    end

    it "reads the opening as LilyPond performs it" do
      expect(bar_events(flow.voices.first).first(4)).to eq [
        ["1:1:000", "eighth", "F5"], ["1:1:480", "sixteenth", "F5"], ["1:1:720", "sixteenth", "G5"], ["1:2:000", "eighth", "A5"]
      ]
    end
  end

  describe "music21's test01.mid" do
    let(:bytes) { File.binread(File.join(fixture_directory, "music21", "test01.mid")) }
    let(:flow) { HeadMusic::MIDI.parse(bytes) }

    it "reads one piano part of one voice in 4/4 on a sixteenth grid, inferring F major for its repeated C" do
      expect([summary(flow), grid(bytes)]).to eq [{
        parts: [["a", :piano, 1]], meter: "4/4", meter_changes: 0, key: "F major", bars: [1, 2], notes: 18
      }, Rational(1, 16)]
    end

    it "leaves no gap in its voice" do
      expect(flow.voices.map(&:first_gap)).to all(be_nil)
    end
  end
end
