require "spec_helper"

describe HeadMusic::Content::Flow::TimelineValues do
  subject(:values) { described_class.new(HeadMusic::Content::Flow::SchemaValues.new) }

  describe "#tempo_ramps" do
    it "answers each ramp as its ends, target, and text" do
      ramps = values.tempo_ramps([{"from" => "2:1", "to" => "3:1", "tempo" => {"beat_value" => "quarter", "beats_per_minute" => 60}, "text" => "rit."}], "timeline")
      expect(ramps.map { |from, to, tempo, text| [from, to, tempo.beats_per_minute, text] }).to eq [["2:1", "3:1", 60, "rit."]]
    end

    it "answers no ramps for an absent list" do
      expect(values.tempo_ramps(nil, "timeline")).to eq []
    end
  end

  describe "#a_tempos" do
    it "says a tempo when written with no text" do
      expect(values.a_tempos([{"position" => "4:1"}], "timeline")).to eq [["4:1", "a tempo"]]
    end

    it "keeps other text" do
      expect(values.a_tempos([{"position" => "4:1", "text" => "Tempo I"}], "timeline")).to eq [["4:1", "Tempo I"]]
    end

    it "raises with path context on empty text" do
      expect { values.a_tempos([{"position" => "4:1", "text" => ""}], "timeline") }
        .to raise_error(ArgumentError, /\Atimeline\.a_tempos\[0\]\.text: tempo text must be a non-empty String/)
    end

    it "raises with path context on a missing position" do
      expect { values.a_tempos([{}], "timeline") }
        .to raise_error(ArgumentError, "timeline.a_tempos[0]: an a tempo needs a position")
    end
  end

  describe "#fermatas" do
    it "doubles a span written with no stretch" do
      expect(values.fermatas([{"from" => "3:1", "to" => "3:2"}], "timeline")).to eq [["3:1", "3:2", 2]]
    end

    it "raises with path context on a stretch below 1" do
      expect { values.fermatas([{"from" => "3:1", "to" => "3:2", "stretch" => 0.5}], "timeline") }
        .to raise_error(ArgumentError, "timeline.fermatas[0].stretch: must be a number of at least 1, got 0.5")
    end
  end

  describe "#tonal_context" do
    it "reads a name into the context it names" do
      expect(values.tonal_context("C dorian", "x")).to be_a HeadMusic::Rudiment::Mode
    end
  end
end
