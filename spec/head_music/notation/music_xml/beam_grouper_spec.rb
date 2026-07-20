require "spec_helper"

RSpec.describe HeadMusic::Notation::MusicXML::BeamGrouper do
  def event(levels, onset, beam_break_before = nil)
    described_class::Event.new(levels: levels, onset: onset, beam_break_before: beam_break_before)
  end

  # Compact each member's beams into [number, type] pairs for readable assertions.
  def pairs(result)
    result.map { |beams| beams.map { |beam| [beam.number, beam.type] } }
  end

  describe ".annotate" do
    it "beams two eighths as a single quarter group" do
      events = [event(1, 0), event(1, 1)]
      expect(pairs(described_class.annotate(events, 2))).to eq([
        [[1, "begin"]],
        [[1, "end"]]
      ])
    end

    it "breaks four eighths into two pairs at the beat boundary" do # rubocop:disable RSpec/ExampleLength
      events = [event(1, 0), event(1, 1), event(1, 2), event(1, 3)]
      result = pairs(described_class.annotate(events, 2))
      expect(result).to eq([
        [[1, "begin"]],
        [[1, "end"]],
        [[1, "begin"]],
        [[1, "end"]]
      ])
      # No primary beam continues across the beat boundary.
      expect(result[1]).to eq([[1, "end"]])
      expect(result[2]).to eq([[1, "begin"]])
    end

    it "beams an eighth followed by two sixteenths (eighth=2 divisions)" do # rubocop:disable RSpec/ExampleLength
      events = [event(1, 0), event(2, 2), event(2, 3)]
      expect(pairs(described_class.annotate(events, 4))).to eq([
        [[1, "begin"]],
        [[1, "continue"], [2, "begin"]],
        [[1, "end"], [2, "end"]]
      ])
    end

    it "hooks a lone trailing sixteenth backward (dotted-eighth + sixteenth)" do
      events = [event(1, 0), event(2, 3)]
      expect(pairs(described_class.annotate(events, 4))).to eq([
        [[1, "begin"]],
        [[1, "end"], [2, "backward hook"]]
      ])
    end

    it "hooks a lone leading sixteenth forward (sixteenth + dotted-eighth)" do
      events = [event(2, 0), event(1, 1)]
      expect(pairs(described_class.annotate(events, 4))).to eq([
        [[1, "begin"], [2, "forward hook"]],
        [[1, "end"]]
      ])
    end

    it "beams four sixteenths in one group at both levels" do # rubocop:disable RSpec/ExampleLength
      events = [event(2, 0), event(2, 1), event(2, 2), event(2, 3)]
      expect(pairs(described_class.annotate(events, 4))).to eq([
        [[1, "begin"], [2, "begin"]],
        [[1, "continue"], [2, "continue"]],
        [[1, "continue"], [2, "continue"]],
        [[1, "end"], [2, "end"]]
      ])
    end

    it "isolates a level-0 event and its beamable neighbors as singletons" do
      events = [event(1, 0), event(0, 1), event(1, 2)]
      result = pairs(described_class.annotate(events, 4))
      expect(result).to eq([[], [], []])
      expect(result.flatten).to be_empty
    end

    it "emits no beam for a size-1 group" do
      events = [event(1, 0)]
      expect(pairs(described_class.annotate(events, 2))).to eq([[]])
    end

    it "joins across a default boundary when beam_break_before is false" do # rubocop:disable RSpec/ExampleLength
      events = [event(1, 0), event(1, 1), event(1, 2, false), event(1, 3)]
      expect(pairs(described_class.annotate(events, 2))).to eq([
        [[1, "begin"]],
        [[1, "continue"]],
        [[1, "continue"]],
        [[1, "end"]]
      ])
    end

    it "splits mid-beat when beam_break_before is true" do # rubocop:disable RSpec/ExampleLength
      events = [event(1, 0), event(1, 1), event(1, 2, true), event(1, 3)]
      expect(pairs(described_class.annotate(events, 4))).to eq([
        [[1, "begin"]],
        [[1, "end"]],
        [[1, "begin"]],
        [[1, "end"]]
      ])
    end
  end
end
