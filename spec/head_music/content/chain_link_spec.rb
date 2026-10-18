require "spec_helper"

describe HeadMusic::Content::ChainLink do
  let(:flow) { HeadMusic::Content::Flow.new }
  let(:voice) { flow.add_voice }
  let(:triplet_eighth) { HeadMusic::Rudiment::RhythmicValue.get(:eighth, tuplet: "3:2") }
  let(:tied) { HeadMusic::Rudiment::RhythmicValue.get("triplet eighth tied to quarter") }

  describe ".of" do
    subject(:links) { described_class.of(voice.last_voice_event) }

    before { voice.place("1:1", tied, "D4") }

    it "has one link per value of the tied chain" do
      expect(links.map { |link| link.rhythmic_value.single_value_name }).to eq ["triplet eighth", "quarter"]
    end

    it "marks the first and last links" do
      expect(links.map { |link| [link.first, link.last] }).to eq [[true, false], [false, true]]
    end

    it "starts the first link where its voice event starts" do
      expect(links.first.start_position.to_s).to eq "1:1:000"
    end

    it "starts a later link where the link before it ends" do
      expect(links.last.start_position).to eq links.first.end_position
    end

    it "ends the last link where its voice event ends" do
      expect(links.last.end_position).to eq voice.last_voice_event.next_position
    end

    it "answers the ratio of its own value" do
      expect(links.map { |link| link.ratio&.to_a }).to eq [[3, 2], nil]
    end

    it "knows that one link ends where the next starts" do
      expect([links.first.ends_at?(links.last.start_position), links.last.starts_at?(links.first.end_position)]).to eq [true, true]
    end

    it "covers its half-open span" do
      link = links.first
      expect([link.start_position, link.end_position].map { |position| link.covers?(position) }).to eq [true, false]
    end
  end

  describe ".between" do
    before { 6.times { voice.place(voice.next_position, triplet_eighth, "C4") } }

    def starts_between(from, to)
      described_class.between(voice, flow.position(from), flow.position(to)).map { |link| link.voice_event.position.to_s }
    end

    it "has the links that sound from one position up to another" do
      expect(starts_between("1:1:320", "1:2")).to eq %w[1:1:320 1:1:640]
    end

    it "includes the event still sounding where the span starts" do
      expect(starts_between("1:1:100", "1:1:320")).to eq %w[1:1:000]
    end

    it "has none where no event sounds" do
      expect(starts_between("5:1", "6:1")).to be_empty
    end
  end

  describe "#rounds?" do
    it "is true for a value that does not land on whole subticks" do
      voice.place("1:1", HeadMusic::Rudiment::RhythmicValue.get(:sixteenth, tuplet: "7:4"), "C4")
      expect(described_class.of(voice.last_voice_event).first.rounds?).to be true
    end

    it "is false for a triplet eighth" do
      voice.place("1:1", triplet_eighth, "C4")
      expect(described_class.of(voice.last_voice_event).first.rounds?).to be false
    end
  end
end
