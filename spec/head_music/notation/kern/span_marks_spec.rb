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
end
