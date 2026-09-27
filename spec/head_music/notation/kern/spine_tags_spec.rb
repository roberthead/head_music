require "spec_helper"

describe HeadMusic::Notation::Kern::SpineTags do
  subject(:tags) { described_class.new([left]) }

  let(:left) { HeadMusic::Notation::Kern::SpineLayout::Track.new("**kern", 0) }
  let(:right) { left.sprout }

  def interpretation(field)
    HeadMusic::Notation::Kern::InterpretationReader.read(field)
  end

  it "records each tag with the line it was read on" do
    tags.read([[left, interpretation("*staff2")]], 3)
    expect([tags.fetch(left).staff, tags.fetch(left).lines]).to eq [2, {staff: 3}]
  end

  it "gives a split's right sub-spine a copy of its sibling's tags" do
    tags.read([[left, interpretation("*staff2")]], 3)
    tags.split(left, right)
    tags.read([[right, interpretation("*staff1")]], 5)
    expect([tags.fetch(left).staff, tags.fetch(left).lines, tags.fetch(right).staff]).to eq [2, {staff: 3}, 1]
  end
end
