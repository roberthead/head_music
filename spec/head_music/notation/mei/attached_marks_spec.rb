require "spec_helper"

describe HeadMusic::Notation::MEI::AttachedMarks do
  def marks(flow)
    plan = HeadMusic::Notation::MEI::RenderPlan.new(flow)
    described_class.new(plan).placed(flow.voices.first, "p1v1").map { |_, bar_element| bar_element.element }
  end

  def summary(flow, name)
    marks(flow).select { |element| element.name == name }.map { |element| element.attributes.compact.except("xml:id") }
  end

  it "points ornaments at their notes, naming a mordent's form" do
    expect(summary(MarkingFixtures.marked_melody, "mordent"))
      .to eq [{"startid" => "#m1-p1v1-b5c1", "form" => "lower"}, {"startid" => "#m1-p1v1-b5c3", "form" => "upper"}]
  end

  it "points a note dynamic at its note" do
    expect(marks(MarkingFixtures.marked_melody).select { |element| element.name == "dynam" }.map(&:text)).to eq %w[sfz fp]
  end

  it "joins a curve's first and last notes" do
    expect(summary(MarkingFixtures.spanned_melody, "phrase")).to eq [{"startid" => "#m1-p1v1-b1c1", "endid" => "#m1-p1v1-b4c3"}]
  end

  it "keys a curve from grace notes apart from one from their main note" do
    flow = TupletFixtures.grace_notes_before_downbeat
    expect(marks(flow).map(&:id)).to include "m1-slur-p1v1-b3c1g-b3c1"
  end
end
