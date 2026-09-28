require "spec_helper"

describe HeadMusic::Notation::LilyPond::SpanMarks do
  subject(:marks) { described_class.new(voice) }

  let(:voice) { MarkingFixtures.four_quarters.voices.first }

  def marks_at(*positions)
    positions.map { |position| [marks.opens_at(position), marks.closes_at(position)] }
  end

  it "writes a slur without a name" do
    voice.add_span(:slur, from: "1:1", to: "1:3")
    expect(marks_at("1:1", "1:3")).to eq [["(", ""], ["", ")"]]
  end

  it "writes a phrasing slur" do
    voice.add_span(:phrase, from: "1:1", to: "2:1")
    expect(marks_at("1:1", "2:1")).to eq [["\\(", ""], ["", "\\)"]]
  end

  it "writes a slur inside a phrasing slur without names" do
    voice.add_span(:phrase, from: "1:1", to: "2:1")
    voice.add_span(:slur, from: "1:2", to: "1:3")
    expect(marks_at("1:2", "1:3")).to eq [["(", ""], ["", ")"]]
  end

  it "names a slur that begins while another is open" do
    voice.add_span(:slur, from: "1:1", to: "1:3")
    voice.add_span(:slur, from: "1:2", to: "1:4")
    expect(marks_at("1:1", "1:2", "1:3", "1:4")).to eq [["(", ""], ["\\=1(", ""], ["", ")"], ["", "\\=1)"]]
  end

  it "names a slur nested in another" do
    voice.add_span(:slur, from: "1:1", to: "1:4")
    voice.add_span(:slur, from: "1:2", to: "1:3")
    expect(marks_at("1:2", "1:3")).to eq [["\\=1(", ""], ["", "\\=1)"]]
  end

  it "names a phrasing slur that begins while another is open" do
    voice.add_span(:phrase, from: "1:1", to: "1:3")
    voice.add_span(:phrase, from: "1:2", to: "1:4")
    expect(marks.opens_at("1:2")).to eq "\\=1\\("
  end

  it "does not name a slur that begins where another ends" do
    voice.add_span(:slur, from: "1:1", to: "1:3")
    voice.add_span(:slur, from: "1:3", to: "2:1")
    expect(marks_at("1:3")).to eq [["(", ")"]]
  end
end
