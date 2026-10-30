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

  describe "Segment#rhythmic_duration!" do
    let(:voice_event) { voice.place("1:1", :half, "C4") }

    it "answers the segment's rhythmic duration" do
      segment = described_class::Segment.new(voice_event, 1, Rational(3, 8), false)
      expect(segment.rhythmic_duration!(ArgumentError)).to eq HeadMusic::Rudiment::RhythmicDuration.get("dotted quarter")
    end

    it "raises the writer's error for a piece no binary note value spans" do
      segment = described_class::Segment.new(voice_event, 1, Rational(1, 3), false)
      expect { segment.rhythmic_duration!(ArgumentError) }
        .to raise_error(ArgumentError, /cannot express the part of the note at 1:1:000 in bar 1 in binary note values/)
    end
  end

  describe "splitting tuplets" do
    def place_in_turn(*values)
      values.each { |value| voice.place(voice.next_position, value, "D4") }
    end

    def split(voice_event)
      described_class.segments_of(voice_event).map { |segment| [segment.bar_number, segment.rhythmic_duration.to_s] }
    end

    let(:error) { HeadMusic::Notation::RenderError }

    before { voice.place("1:1", "dotted half", "C4") }

    it "splits the middle of three 3:2 quarters from beat 4 into tied triplet eighths" do
      place_in_turn(*Array.new(3, HeadMusic::Rudiment::RhythmicValue.get(:quarter, tuplet: "3:2")))
      expect(voice.voice_events.drop(1).map { |voice_event| split(voice_event) }).to eq [
        [[1, "triplet quarter"]], [[1, "triplet eighth"], [2, "triplet eighth"]], [[2, "triplet quarter"]]
      ]
    end

    it "splits 7:4 eighths from beat 4 at the exact barline despite rounded positions" do
      place_in_turn(*Array.new(7, HeadMusic::Rudiment::RhythmicValue.get(:eighth, tuplet: "7:4")))
      crossing = voice.voice_events[4]
      expect([crossing.position.to_s, summary(described_class.segments_of(crossing)), split(crossing)])
        .to eq ["1:4:822:206", [[1, Rational(1, 28), true], [2, Rational(1, 28), false]], [[1, "7:4 sixteenth"], [2, "7:4 sixteenth"]]]
    end

    it "gives each piece its exact onset in its bar" do
      place_in_turn(*Array.new(7, HeadMusic::Rudiment::RhythmicValue.get(:eighth, tuplet: "7:4")))
      expect(described_class.segments_of(voice.voice_events[4]).map(&:offset)).to eq [Rational(27, 28), 0]
    end

    it "cuts a chain mixing ratios link by link" do
      place_in_turn(*Array.new(2, HeadMusic::Rudiment::RhythmicValue.get(:eighth, tuplet: "3:2")),
        HeadMusic::Rudiment::RhythmicValue.get("triplet eighth tied to half"))
      expect(split(voice.voice_events.last)).to eq [[1, "triplet eighth"], [2, "half"]]
    end

    it "answers the onset of a rounded position exactly" do
      place_in_turn(*Array.new(2, HeadMusic::Rudiment::RhythmicValue.get(:eighth, tuplet: "7:4")))
      expect(described_class.onset_in_bar(voice.voice_events.last)).to eq Rational(3, 4) + Rational(1, 14)
    end

    context "with a 2:3 duplet crossing a barline in 6/8" do
      let(:meter) { "6/8" }
      let(:duplets) { flow.add_voice }

      before do
        duplets.place("1:1", :half, "C4")
        2.times { duplets.place(duplets.next_position, HeadMusic::Rudiment::RhythmicValue.get(:eighth, tuplet: "2:3"), "D4") }
      end

      it "raises, naming the ratio" do
        expect { described_class.segments_of(duplets.voice_events.last).first.rhythmic_duration!(error) }
          .to raise_error(error, /cannot express the part of the note at 1:6:240 in bar 1 in binary note values under its 2:3 ratio/)
      end

      it "raises, naming the group" do
        duplets.group_tuplet(from: "1:5", to: "2:2")
        expect { described_class.segments_of(duplets.voice_events.last).first.rhythmic_duration!(error) }
          .to raise_error(error, /under the 2:3 tuplet from 1:5:000 to 2:2:000/)
      end
    end
  end

  describe ".position_at" do
    def position_at(bar_number, offset)
      described_class.position_at(flow, bar_number, offset).to_s
    end

    {0 => "3:1:000", Rational(1, 4) => "3:2:000", Rational(5, 8) => "3:3:480", Rational(3, 32) => "3:1:360"}.each do |offset, code|
      it "places #{offset} of a whole note into a 4/4 bar at #{code}" do
        expect(position_at(3, offset)).to eq code
      end
    end

    context "with a compound meter" do
      let(:meter) { "6/8" }

      {Rational(3, 8) => "2:4:000", Rational(5, 8) => "2:6:000", Rational(11, 16) => "2:6:240"}.each do |offset, code|
        it "places #{offset} of a whole note into a 6/8 bar at #{code}, counting eighths" do
          expect(position_at(2, offset)).to eq code
        end
      end
    end

    it "carries a fraction of a tick into subticks" do
      expect(position_at(1, Rational(1, 7680))).to eq "1:1:000:120"
    end

    it "inverts offset_in_bar" do
      position = flow.position("4:3:240")
      expect(described_class.position_at(flow, 4, described_class.offset_in_bar(position))).to eq position
    end

    it "inverts offset_in_bar with subticks" do
      position = flow.position("4:3:240:007")
      expect(described_class.position_at(flow, 4, described_class.offset_in_bar(position))).to eq position
    end
  end

  describe ".offset_in_bar" do
    it "counts subticks" do
      expect(described_class.offset_in_bar(flow.position("1:1:000:120"))).to eq Rational(1, 7680)
    end

    it "splits a note starting on a subtick at its exact place" do
      voice.place("1:1", "dotted two hundred fifty-sixth", "C4")
      voice.place(voice.next_position, :whole, "D4")
      expect(summary(described_class.segments_of(voice.voice_events.last))).to eq [
        [1, Rational(509, 512), true], [2, Rational(3, 512), false]
      ]
    end
  end

  describe ".mark_offset" do
    let(:flow) { TupletFixtures.septuplet }
    let(:fourth) { flow.voices.first.voice_events[3] }

    it "answers the exact onset of a note starting at a rounded position" do
      expect(described_class.mark_offset(flow, fourth.position)).to eq Rational(3, 28)
    end

    it "answers the position itself where no note starts" do
      expect(described_class.mark_offset(flow, flow.position("1:3"))).to eq Rational(1, 2)
    end
  end
end
