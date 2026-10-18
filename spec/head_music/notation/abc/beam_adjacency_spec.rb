require "spec_helper"

describe HeadMusic::Notation::ABC::BeamAdjacency do
  subject(:beams) { described_class.new }

  it "reports no beam break for the first note" do
    expect(beams.next_break).to be_nil
  end

  it "beams a note to the previous one (false) after the first" do
    beams.next_break
    expect(beams.next_break).to be false
  end

  it "forces a break when one was explicitly marked" do
    beams.next_break
    beams.mark_break
    expect(beams.next_break).to be true
  end

  it "treats the next note as un-beamed after a reset" do
    beams.next_break
    beams.reset
    expect(beams.next_break).to be_nil
  end
end
