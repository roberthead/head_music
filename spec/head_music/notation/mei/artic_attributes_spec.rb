require "spec_helper"

describe HeadMusic::Notation::MEI::ArticAttributes do
  def document(flow)
    parse_mei(HeadMusic::Notation::MEI.render(flow))
  end

  def abc(body)
    HeadMusic::Notation::ABC.parse("X:1\nT:Artic\nM:4/4\nL:1/4\nK:C\n#{body}\n")
  end

  it "writes each articulation in MEI's list" do
    flow = MarkingFixtures.marked_melody
    expect(mei_attributes(document(flow), "//mei:note[@artic]", "artic").uniq).to eq %w[stacc ten acc stacciss marc]
  end

  it "lists several articulations on one note" do
    flow = abc("C D E F|]")
    flow.voices.first.voice_events.first.articulate(:staccato).articulate(:accent)
    expect(mei_attributes(document(flow), "//mei:note[@artic]", "artic")).to eq ["acc stacc"]
  end

  it "writes a chord's articulation on the chord rather than its notes" do
    flow = abc("[CEG] D E F|]")
    flow.voices.first.voice_events.first.articulate(:tenuto)
    xml = document(flow)
    expect([mei_attributes(xml, "//mei:chord", "artic"), mei_elements(xml, "//mei:note[@artic]")]).to eq [["ten"], []]
  end

  it "writes the articulation of a tied or bar-split note on its first piece only" do
    flow = abc("C D E F-|F G A B|]")
    flow.voices.first.voice_events[3].articulate(:accent)
    expect(mei_attributes(document(flow), "//mei:note[@artic]", "xml:id")).to eq ["m1-p1v1-b1c4"]
  end

  it "writes a grace note's own articulation" do
    flow = TupletFixtures.grace_notes_before_downbeat
    expect(mei_attributes(document(flow), "//mei:note[@grace][@artic]", "artic")).to eq ["stacc"]
  end

  it "adds nothing to a rest" do
    plan = HeadMusic::Notation::MEI::RenderPlan.new(abc("z D E F|]"))
    item = plan.items(plan.flow.voices.first, 1).first
    node = HeadMusic::Notation::MEI::EventWriter::Node.new(kind: :rest, id: item.id, item: item)
    expect(described_class.new(plan).event_attributes(node)).to eq({})
  end
end
