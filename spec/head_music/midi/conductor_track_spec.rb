require "spec_helper"

describe HeadMusic::MIDI::ConductorTrack do
  subject(:events) { described_class.new(flow, HeadMusic::MIDI::PerformanceTimeline.new(flow)).events }

  let(:flow) { HeadMusic::Content::Flow.new(name: "Conductor", meter: meter, key_signature: key, tempo: tempo) }
  let(:meter) { "4/4" }
  let(:key) { "C major" }
  let(:tempo) { "quarter = 120" }

  before { flow.add_voice.place("1:1", :whole, "C4") unless flow.voices.any? }

  def of(kind)
    events.grep(kind)
  end

  it "names the sequence for the flow" do
    expect(events.first).to eq HeadMusic::MIDI::Text.new(0, :sequence_name, "Conductor")
  end

  it "writes the opening meter, tempo, and key once" do
    expect(events.drop(1)).to eq [
      HeadMusic::MIDI::TimeSignature.new(0, 4, 4, 24),
      HeadMusic::MIDI::Tempo.new(0, 500_000),
      HeadMusic::MIDI::KeySignature.new(0, 0, false)
    ]
  end

  context "with 6/8 at a dotted quarter of 60" do
    let(:meter) { "6/8" }
    let(:tempo) { "dotted quarter = 60" }

    it "writes 36 clocks per click" do
      expect(of(HeadMusic::MIDI::TimeSignature)).to eq [HeadMusic::MIDI::TimeSignature.new(0, 6, 8, 36)]
    end

    it "writes 666,667 microseconds per quarter" do
      expect(of(HeadMusic::MIDI::Tempo).map(&:microseconds_per_quarter)).to eq [666_667]
    end
  end

  context "with 2/2" do
    let(:meter) { "2/2" }

    it "writes 48 clocks per click" do
      expect(of(HeadMusic::MIDI::TimeSignature).map(&:clocks_per_click)).to eq [48]
    end
  end

  context "with 6/2" do
    let(:meter) { "6/2" }

    it "writes 144 clocks per dotted-whole click" do
      expect(of(HeadMusic::MIDI::TimeSignature)).to eq [HeadMusic::MIDI::TimeSignature.new(0, 6, 2, 144)]
    end
  end

  context "with C minor" do
    let(:key) { "C minor" }

    it "writes three flats, minor" do
      expect(of(HeadMusic::MIDI::KeySignature)).to eq [HeadMusic::MIDI::KeySignature.new(0, -3, true)]
    end
  end

  context "with A aeolian" do
    let(:key) { "A aeolian" }

    it "writes the mode as minor" do
      expect(of(HeadMusic::MIDI::KeySignature).map(&:minor)).to eq [true]
    end
  end

  context "with D dorian" do
    let(:key) { "D dorian" }

    it "writes another mode as major" do
      expect(of(HeadMusic::MIDI::KeySignature)).to eq [HeadMusic::MIDI::KeySignature.new(0, 0, false)]
    end
  end

  context "with G-sharp major" do
    let(:key) { "G# major" }

    it "writes the key's enharmonic, A-flat major" do
      expect(of(HeadMusic::MIDI::KeySignature).map(&:fifths)).to eq [-4]
    end
  end

  context "with changes and a D.C. back over them" do
    let(:flow) do
      HeadMusic::Content::Flow.new(name: "Changes", meter: "4/4", key_signature: "G major", tempo: "quarter = 100").tap do |changing|
        voice = changing.add_voice
        voice.place("1:1", :whole, "G4")
        voice.place("2:1", "dotted half", "F4")
        voice.place("3:1", "dotted half", "A4")
        changing.change_meter(2, "3/4")
        changing.change_key_signature(2, "F major")
        changing.change_tempo(2, "quarter = 80")
        changing.bar(3).jump = HeadMusic::Content::Jump.new(:da_capo)
      end
    end

    it "writes each change where it falls, and restores the opening values after the jump" do
      expect(of(HeadMusic::MIDI::TimeSignature).map { |event| [event.tick, event.numerator] }).to eq(
        [[0, 4], [1, 3], [Rational(5, 2), 4], [Rational(7, 2), 3]]
      )
    end

    it "restores the tempo after the jump" do
      expect(of(HeadMusic::MIDI::Tempo).map(&:microseconds_per_quarter)).to eq [600_000, 750_000, 600_000, 750_000]
    end

    it "restores the key after the jump" do
      expect(of(HeadMusic::MIDI::KeySignature).map(&:fifths)).to eq [1, -1, 1, -1]
    end

    it "writes nothing where nothing changes" do
      expect(events.map(&:tick).uniq).to eq [0, 1, Rational(5, 2), Rational(7, 2)]
    end
  end

  context "with a pickup a whole number of counts long" do
    let(:meter) { "3/4" }

    before do
      voice = flow.add_voice
      voice.place("0:3", :quarter, "G4")
      voice.place("1:1", "dotted half", "C5")
    end

    it "writes the pickup's own meter, then the flow's at bar 1" do
      expect(of(HeadMusic::MIDI::TimeSignature)).to eq [
        HeadMusic::MIDI::TimeSignature.new(0, 1, 4, 24),
        HeadMusic::MIDI::TimeSignature.new(Rational(1, 4), 3, 4, 24)
      ]
    end
  end

  context "with a pickup of part of a count" do
    let(:meter) { "3/4" }

    before do
      voice = flow.add_voice
      voice.place("0:3", :eighth)
      voice.place("0:3:480", :eighth, "G4")
      voice.place("1:1", "dotted half", "C5")
    end

    it "writes the flow's meter from the start" do
      expect(of(HeadMusic::MIDI::TimeSignature)).to eq [HeadMusic::MIDI::TimeSignature.new(0, 3, 4, 24)]
    end
  end
end
