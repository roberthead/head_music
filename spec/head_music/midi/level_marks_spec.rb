require "spec_helper"

describe HeadMusic::MIDI::LevelMarks do
  subject(:marks) { described_class.of(voice) }

  let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nT:Marks\nM:4/4\nL:1/4\nK:C\n#{body}\n") }
  let(:voice) { flow.voices.first }

  def position(code)
    flow.position(code)
  end

  def level(name)
    HeadMusic::Rudiment::Dynamic.get(name)
  end

  def mark(code, rank, name)
    described_class::Mark.new(position(code), rank, level(name))
  end

  describe ".of" do
    let(:body) { "!p!C !fp!D E F|" }

    it "ranks the part's level, then the voice's, then the level a note dynamic leaves" do
      voice.part.place_dynamic("1:2", :ff)
      voice.place_dynamic("1:2", :pp)
      expect(marks.at(position("1:2"))).to eq mark("1:2", described_class::ACCENT_RANK, "p")
    end
  end

  describe "#at" do
    let(:body) { "!p!C D !f!E F|" }

    it "is the last mark at or before a position" do
      expect([marks.at(position("1:2")).level, marks.at(position("1:3")).level]).to eq [level("p"), level("f")]
    end

    it "is nil before the first mark" do
      expect(described_class.new([mark("1:2", 0, "p")]).at(position("1:1"))).to be_nil
    end
  end

  describe "#before_accent" do
    let(:body) { "!mf!C !fp!D E F|" }

    it "is the level in force before the note there leaves its own" do
      expect(marks.before_accent(position("1:2"))).to eq level("mf")
    end

    it "is the level in force where no note leaves one" do
      expect(marks.before_accent(position("1:3"))).to eq level("p")
    end
  end

  describe "#with" do
    let(:body) { "!p!C D E F|" }

    it "sorts the added marks in, below a level placed at their position" do
      combined = marks.with([mark("1:1", described_class::FOLLOW_THROUGH_RANK, "ff"), mark("1:3", described_class::FOLLOW_THROUGH_RANK, "f")])
      expect([combined.at(position("1:1")).level, combined.at(position("1:3")).level]).to eq [level("p"), level("f")]
    end
  end

  describe "#levels" do
    let(:body) { "C !p!D E !f!F|" }

    it "answers the level in force at each voice event, nil before any" do
      levels = marks.levels(voice.voice_events)
      expect(voice.voice_events.map { |voice_event| levels[voice_event]&.name_key }).to eq [nil, "p", "p", "f"]
    end
  end
end
