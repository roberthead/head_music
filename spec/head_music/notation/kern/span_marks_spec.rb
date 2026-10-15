require "spec_helper"

describe HeadMusic::Notation::Kern::SpanMarks do
  subject(:marks) { described_class.new(voice) }

  let(:voice) { MarkingFixtures.four_quarters.voices.first }

  def marks_at(*positions)
    positions.map { |position| [marks.opens_at(position), marks.closes_at(position)] }
  end

  it "opens a slur on its first note and closes it on its last" do
    voice.add_span(:slur, from: "1:1", to: "1:3")
    expect(marks_at("1:1", "1:3")).to eq [["(", ""], ["", ")"]]
  end

  it "writes a phrase in braces" do
    voice.add_span(:phrase, from: "1:1", to: "2:1")
    expect(marks_at("1:1", "2:1")).to eq [["{", ""], ["", "}"]]
  end

  it "opens a phrase before a slur that starts with it" do
    voice.add_span(:slur, from: "1:1", to: "1:2")
    voice.add_span(:phrase, from: "1:1", to: "2:1")
    expect(marks.opens_at("1:1")).to eq "{("
  end

  it "opens the longer of two slurs that start together first, at one level" do
    voice.add_span(:slur, from: "1:1", to: "1:2")
    voice.add_span(:slur, from: "1:1", to: "1:4")
    expect(marks_at("1:1", "1:2", "1:4")).to eq [["((", ""], ["", ")"], ["", ")"]]
  end

  it "elides a slur that crosses another" do
    voice.add_span(:slur, from: "1:1", to: "1:3")
    voice.add_span(:slur, from: "1:2", to: "1:4")
    expect(marks_at("1:2", "1:4")).to eq [["&(", ""], ["", "&)"]]
  end

  it "keeps a slur that begins where another ends at the first level" do
    voice.add_span(:slur, from: "1:1", to: "1:3")
    voice.add_span(:slur, from: "1:3", to: "2:1")
    expect(marks_at("1:3")).to eq [["(", ")"]]
  end

  it "keeps a slur and a phrase that cross at the first level, since each kind pairs on its own" do
    voice.add_span(:phrase, from: "1:1", to: "1:3")
    voice.add_span(:slur, from: "1:2", to: "1:4")
    expect(marks_at("1:2", "1:3")).to eq [["(", ""], ["", "}"]]
  end

  describe "spans from grace notes" do
    before do
      %w[1:3 1:4].each { |position| voice.voice_event_at(position).add_grace_note("B4", :sixteenth) }
    end

    it "opens a slur from grace notes on them, apart from the note's own opens" do
      voice.add_span(:slur, from: "1:3", to: "1:3", from_grace: true)
      voice.add_span(:slur, from: "1:3", to: "1:4")
      expect([marks.grace_opens_at("1:3"), marks_at("1:3")]).to eq ["(", [["(", ")"]]]
    end

    it "elides a slur from grace notes that outlasts a slur ending on its note" do
      voice.add_span(:slur, from: "1:1", to: "1:3")
      voice.add_span(:slur, from: "1:3", to: "1:4", from_grace: true)
      expect([marks.grace_opens_at("1:3"), marks_at("1:3", "1:4")]).to eq ["&(", [["", ")"], ["", "&)"]]]
    end

    it "keeps a slur from grace notes to their own note at the first level inside one ending there" do
      voice.add_span(:slur, from: "1:1", to: "1:3")
      voice.add_span(:slur, from: "1:3", to: "1:3", from_grace: true)
      expect([marks.grace_opens_at("1:3"), marks.closes_at("1:3")]).to eq ["(", "))"]
    end

    it "elides a slur starting on a note inside a longer slur from its grace notes" do
      voice.add_span(:slur, from: "1:3", to: "1:4", from_grace: true)
      voice.add_span(:slur, from: "1:3", to: "2:1")
      expect([marks.grace_opens_at("1:3"), marks.opens_at("1:3")]).to eq ["(", "&("]
    end
  end
end
