require "spec_helper"

describe HeadMusic::MIDI::Preflight do
  subject(:preflight) { described_class.new(flow) }

  let(:flow) { HeadMusic::Content::Flow.new(name: "Preflight") }
  let(:voice) { flow.add_voice }

  def failure
    preflight.check
    nil
  rescue HeadMusic::MIDI::RenderError => error
    error.message
  end

  it "refuses a flow with no voice events" do
    flow.add_voice
    expect(failure).to include("Preflight has no voice events")
  end

  it "accepts a flow of rests" do
    voice.place("1:1", :whole)
    expect(failure).to be_nil
  end

  it "refuses a pitch above MIDI's range, naming it and its position" do
    voice.place("1:1", :quarter, "C4")
    voice.place("1:2", :quarter, "A9")
    expect(failure).to include("A9 at 1:2:000 sounds at MIDI key 129")
  end

  it "refuses a grace note below MIDI's range" do
    voice.place("1:1", :quarter, "C4").add_grace_note("Cb-1", :eighth)
    expect(failure).to include("C♭-1 at 1:1:000 sounds at MIDI key -1")
  end

  context "when transposed" do
    subject(:preflight) { described_class.new(flow, transposed: true) }

    let(:voice) { flow.add_part(instrument: "piccolo_flute").add_voice }

    it "refuses a written pitch that sounds out of range" do
      voice.place("1:1", :quarter, "G9")
      expect(failure).to include("G9 at 1:1:000 sounds at MIDI key 139")
    end

    it "accepts the written pitch when not transposed" do
      voice.place("1:1", :quarter, "G9")
      expect(described_class.new(flow).check).to be_a described_class
    end
  end

  it "refuses a meter whose denominator is not a power of two" do
    voice.place("1:1", :quarter, "C4")
    flow.change_meter(3, "5/12")
    expect(failure).to include("cannot hold 5/12 in bar 3")
  end

  it "refuses a meter with more than 255 counts" do
    voice.place("1:1", :quarter, "C4")
    flow.change_meter(3, "256/4")
    expect(failure).to include("cannot hold 256/4 in bar 3")
  end

  it "refuses a tempo of 0 bpm" do
    voice.place("1:1", :quarter, "C4")
    flow.change_tempo(1, "quarter = 0")
    expect(failure).to include("0 bpm in bar 1")
  end

  it "refuses a tempo too slow for MIDI to hold" do
    voice.place("1:1", :quarter, "C4")
    flow.change_tempo(1, HeadMusic::Rudiment::Tempo.new("quarter", 3))
    expect(failure).to match(/cannot hold quarter = 3.0 in bar 1/)
  end

  it "refuses a tempo too fast for MIDI to hold" do
    voice.place("1:1", :quarter, "C4")
    flow.change_tempo(1, HeadMusic::Rudiment::Tempo.new("quarter", 200_000_000))
    expect(failure).to include("cannot hold quarter")
  end

  it "reports a malformed order as a render error" do
    voice.place("1:1", :whole, "C4")
    flow.bar(1).jump = HeadMusic::Content::Jump.new(:da_capo, to: :fine)
    expect(failure).to include("Fine")
  end

  it "answers the bars as played" do
    voice.place("1:1", :whole, "C4")
    expect(preflight.played_bars.map(&:number)).to eq [1]
  end

  describe "#check_ticks" do
    it "accepts a performance a MIDI file can count" do
      expect { preflight.check_ticks(0x0FFFFFFF, 480) }.not_to raise_error
    end

    it "refuses one longer than a MIDI file can count" do
      expect { preflight.check_ticks(0x10000000, 480) }.to raise_error(HeadMusic::MIDI::RenderError, /more than a MIDI file can count/)
    end
  end
end
