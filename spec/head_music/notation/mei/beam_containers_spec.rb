require "spec_helper"

describe HeadMusic::Notation::MEI::BeamContainers do
  def abc(body)
    HeadMusic::Notation::ABC.parse("X:1\nT:Beams\nM:4/4\nL:1/8\nK:C\n#{body}\n")
  end

  subject(:beam_containers) { described_class.new(plan, spans) }

  let(:plan) { HeadMusic::Notation::MEI::RenderPlan.new(flow) }
  let(:spans) { [] }
  let(:flow) { abc("CDEF G2 z2|]") }
  let(:voice) { flow.voices.first }

  def tuplet(first, last)
    HeadMusic::Notation::MEI::LayerContainers::Container.new("tuplet", "t", first, last, {})
  end

  it "beams the eighths of a beat group as a range of items" do
    expect(beam_containers.beams(voice, 1, []).map { |beam| [beam.first, beam.last] }).to eq [[0, 3]]
  end

  it "ids a beam by its first item" do
    expect(beam_containers.beams(voice, 1, []).first.id).to eq "m1-beam-p1v1-b1c1"
  end

  it "leaves a beam that nests with a tuplet in the layer" do
    expect(beam_containers.beams(voice, 1, [tuplet(0, 1)]).length).to eq 1
    expect(spans).to be_empty
  end

  it "makes a beam that cuts across a tuplet a beamSpan" do
    expect(beam_containers.beams(voice, 1, [tuplet(2, 4)])).to be_empty
    expect(spans.map { |span| span.element.attributes["plist"] }).to eq [
      "#m1-p1v1-b1c1 #m1-p1v1-b1c1t480 #m1-p1v1-b1c2 #m1-p1v1-b1c2t480"
    ]
  end

  it "is empty for a bar the voice places nothing in" do
    expect(beam_containers.beams(voice, 2, [])).to eq []
  end
end
