require "spec_helper"

describe HeadMusic::Notation::MEI::FermataControls do
  def fermatas(flow)
    mei_attributes(parse_mei(flow.to_mei), "//mei:fermata", "startid", "staff")
  end

  it "writes a <fermata> on the event each voice sounds where a fermata begins, rests included, on its staff" do
    flow = HeadMusic::Notation::ABC.parse("X:1\nT:Held\nM:2/4\nL:1/4\nV:S\nV:B\nK:C\nV:S\nc z|]\nV:B\nC, C,/ D,/|]\n")
    flow.add_fermata("1:2:480", :eighth)
    expect(fermatas(flow)).to eq [%w[#m1-p1v1-b1c2 1], %w[#m1-p2v1-b1c2t480 2]]
  end

  it "marks the written piece of a carrier that sounds where the fermata begins" do
    flow = HeadMusic::Content::Flow.new(meter: "2/4").tap { |tied| tied.add_voice.place("1:1", :whole, "C4") }
    flow.add_fermata("2:1", :half)
    expect(fermatas(flow)).to eq [%w[#m1-p1v1-b2c1 1]]
  end

  it "writes none for a flow with no fermatas" do
    flow = HeadMusic::Content::Flow.new.tap { |plain| plain.add_voice.place("1:1", :whole, "C4") }
    expect(fermatas(flow)).to eq []
  end
end
