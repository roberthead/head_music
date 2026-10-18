require "spec_helper"

describe HeadMusic::Notation::LilyPond::HairpinMarks do
  subject(:hairpin_marks) { described_class.new }

  let(:flow) { MarkingFixtures.four_quarters }
  let(:voice) { flow.voices.first }
  let(:marks_class) { HeadMusic::Notation::LilyPond::MarkReader::Marks }

  def add(position, **marks)
    hairpin_marks.add(flow.position(position), marks_class.new(**marks))
  end

  def pair(written_end: flow.position("3:1"))
    hairpin_marks.pair([voice], written_end: written_end, final_barline: flow.final_barline_position)
  end

  def spans
    voice.spans.map { |span| [span.kind, span.from.to_s, span.to.to_s] }
  end

  it "pairs a start with the next dynamic" do
    add("1:1", hairpin_marks: [:crescendo])
    add("1:3", level: "f")
    pair
    expect(spans).to eq [[:crescendo, flow.position("1:1").to_s, flow.position("1:3").to_s]]
  end

  it "reads a level and a start at one moment alike in either order" do
    add("1:1", hairpin_marks: [:diminuendo], level: "f")
    add("1:3", hairpin_marks: [:end])
    pair
    expect(spans.map(&:first)).to eq [:diminuendo]
  end

  it "draws a hairpin ending at the written end to the final barline" do
    add("1:1", hairpin_marks: [:crescendo])
    add("1:3", hairpin_marks: [:end])
    pair(written_end: flow.position("1:3"))
    expect(spans.first.last).to eq flow.final_barline_position.to_s
  end

  it "drops an unterminated hairpin and a stray end" do
    add("1:1", hairpin_marks: [:end])
    add("1:3", hairpin_marks: [:crescendo])
    pair
    expect(spans).to be_empty
  end
end
