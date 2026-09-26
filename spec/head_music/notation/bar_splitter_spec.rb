require "spec_helper"

describe HeadMusic::Notation::BarSplitter do
  let(:flow) { HeadMusic::Content::Flow.new(name: "Split", key_signature: "C major", meter: meter) }
  let(:meter) { "4/4" }
  let(:voice) { flow.add_voice }

  def summary(segments)
    segments.map { |segment| [segment.bar_number, segment.fraction, segment.continues] }
  end

  describe ".segments_of" do
    it "leaves a voice event that fits its bar whole, with no fraction" do
      voice_event = voice.place("1:1", :half, "C4")
      expect(summary(described_class.segments_of(voice_event))).to eq [[1, nil, false]]
    end

    it "leaves a voice event that ends on the barline whole" do
      voice_event = voice.place("1:3", :half, "C4")
      expect(summary(described_class.segments_of(voice_event))).to eq [[1, nil, false]]
    end

    it "splits a voice event that crosses the barline into a piece per bar" do
      voice_event = voice.place("1:4", :half, "C4")
      expect(summary(described_class.segments_of(voice_event))).to eq [
        [1, Rational(1, 4), true],
        [2, Rational(1, 4), false]
      ]
    end

    it "splits between different durations" do
      voice_event = voice.place("1:3", :dotted_half, "C4")
      expect(summary(described_class.segments_of(voice_event))).to eq [
        [1, Rational(1, 2), true],
        [2, Rational(1, 4), false]
      ]
    end

    it "gives the last piece a full bar when the voice event ends on a later barline" do
      voice_event = voice.place("1:1", :"double whole", "C4")
      expect(summary(described_class.segments_of(voice_event))).to eq [
        [1, Rational(1), true],
        [2, Rational(1), false]
      ]
    end

    it "keeps the voice event on every segment" do
      voice_event = voice.place("1:4", :half, "C4")
      expect(described_class.segments_of(voice_event).map(&:voice_event)).to all(equal(voice_event))
    end

    context "with a compound meter" do
      let(:meter) { "6/8" }

      it "measures the bar in the meter's own counts" do
        voice_event = voice.place("1:6", :quarter, "C4")
        expect(summary(described_class.segments_of(voice_event))).to eq [
          [1, Rational(1, 8), true],
          [2, Rational(1, 8), false]
        ]
      end
    end
  end

  describe ".segments" do
    before do
      voice.place("1:1", :dotted_half, "C4")
      voice.place("1:4", :half, "D4")
      voice.place("2:2", :dotted_half, "E4")
    end

    it "yields the segments of each voice event in order" do
      expect(summary(described_class.segments(voice.voice_events))).to eq [
        [1, nil, false], [1, Rational(1, 4), true], [2, Rational(1, 4), false], [2, nil, false]
      ]
    end
  end

  describe "Segment#rhythmic_value!" do
    let(:voice_event) { voice.place("1:1", :half, "C4") }

    it "answers the segment's rhythmic value" do
      segment = described_class::Segment.new(voice_event, 1, Rational(3, 8), false)
      expect(segment.rhythmic_value!(ArgumentError)).to eq HeadMusic::Rudiment::RhythmicValue.get("dotted quarter")
    end

    it "raises the writer's error for a piece no binary note value spans" do
      segment = described_class::Segment.new(voice_event, 1, Rational(1, 3), false)
      expect { segment.rhythmic_value!(ArgumentError) }
        .to raise_error(ArgumentError, /cannot express the part of the note at 1:1:000 in bar 1 in binary note values/)
    end
  end
end
