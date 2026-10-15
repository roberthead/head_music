require "spec_helper"

describe HeadMusic::Notation::MEI::LayerTree do
  def layer(flow, bar_number = 1, voice_index = 0)
    plan = HeadMusic::Notation::MEI::RenderPlan.new(flow)
    voice = flow.voices[voice_index]
    tree = described_class.new(plan, HeadMusic::Notation::MEI::EventWriter.new(plan))
    tree.children(voice, bar_number, plan.items(voice, bar_number))
  end

  # Each element as its name, a grace note as "grace", and a container with
  # its children.
  def outline(elements)
    elements.map do |element|
      next [element.name, outline(element.children)] if %w[beam tuplet].include?(element.name)

      element.attributes["grace"] ? "grace" : element.name
    end
  end

  def default_beamed(abc)
    HeadMusic::Notation::ABC.parse(abc).tap do |flow|
      flow.voices.flat_map(&:voice_events).each { |voice_event| voice_event.beam_break_before = nil }
    end
  end

  it "is the layer builder of the measure writer" do
    expect(HeadMusic::Notation::MEI::MeasureWriter.layer_builder).to eq described_class
  end

  it "beams eighths by the beat" do
    flow = default_beamed("X:1\nM:4/4\nL:1/8\nK:C\nCDEF G2 AB |]\n")
    expect(outline(layer(flow))).to eq [["beam", %w[note note]], ["beam", %w[note note]], "note", ["beam", %w[note note]]]
  end

  it "groups by the dotted quarter in 6/8" do
    flow = default_beamed("X:1\nM:6/8\nL:1/8\nK:C\nCDEFGA |]\n")
    expect(outline(layer(flow))).to eq [["beam", %w[note note note]], ["beam", %w[note note note]]]
  end

  it "honors an authored break" do
    flow = HeadMusic::Notation::ABC.parse("X:1\nM:6/8\nL:1/8\nK:C\nab c def |]\n")
    expect(outline(layer(flow))).to eq [["beam", %w[note note]], "note", ["beam", %w[note note note]]]
  end

  it "leaves rests out of beams" do
    flow = HeadMusic::Notation::ABC.parse("X:1\nT:Beams\nM:4/4\nL:1/8\nK:C\nCD z2 EF z2 |]\n")
    expect(outline(layer(flow))).to eq [["beam", %w[note note]], "rest", ["beam", %w[note note]], "rest"]
  end

  it "beams chords" do
    flow = HeadMusic::Notation::ABC.parse("X:1\nM:2/4\nL:1/8\nK:C\n[CE][DF] G2 |]\n")
    expect(outline(layer(flow))).to eq [["beam", %w[chord chord]], "note"]
  end

  it "writes a lone measure rest bare" do
    flow = HeadMusic::Notation::ABC.parse("X:1\nM:2/4\nL:1/8\nK:C\nz4 | CDEF |]\n")
    expect(outline(layer(flow))).to eq ["mRest"]
  end

  describe "grace notes" do
    let(:flow) { MEILayerFixtures.graces_in_beams }

    it "places a grace note before a beam's first member outside it, and before an inner member inside it" do
      expect(outline(layer(flow))).to eq ["grace", ["beam", %w[note grace note]], ["beam", %w[note grace note]]]
    end

    it "places a grace note before an inner member of a triplet inside it" do
      expect(outline(layer(flow, 2))).to eq [["tuplet", [["beam", %w[note grace note note]]]], "note"]
    end
  end

  describe "tuplets" do
    it "writes a bracket as a tuplet of its ratio" do
      tuplet = layer(TupletFixtures.triplets).first
      expect([tuplet.name, tuplet.attributes]).to eq ["tuplet", {"num" => 3, "numbase" => 2}]
    end

    it "puts the beam over the same notes inside the tuplet" do
      expect(outline(layer(TupletFixtures.triplets))).to eq [
        ["tuplet", [["beam", %w[note note note]]]],
        ["tuplet", [["beam", %w[note note note]]]],
        ["tuplet", %w[note note note]]
      ]
    end

    it "puts a tuplet inside a beam that holds more" do
      expect(outline(layer(MEILayerFixtures.tuplet_inside_beam))).to eq [["beam", ["note", ["tuplet", %w[note note note]]]], "note"]
    end

    it "leaves unbeamed a beam that cuts across a tuplet, for a beamSpan to draw" do
      expect(outline(layer(MEILayerFixtures.beams_across_tuplet))).to eq ["note", ["tuplet", %w[note note note note note note]], "note", "note"]
    end

    describe "a bracket across a barline" do
      let(:flow) { TupletFixtures.tuplet_crossing_barline }

      it "writes a hidden tuplet in each bar" do
        tuplets = [1, 2].map { |bar_number| layer(flow, bar_number).find { |element| element.name == "tuplet" } }
        expect(tuplets.map(&:attributes)).to all eq("num" => 3, "numbase" => 2, "bracket.visible" => "false", "num.visible" => "false")
      end

      it "holds in each bar the pieces written there" do
        expect([1, 2].map { |bar_number| outline(layer(flow, bar_number)) }).to eq [
          ["note", ["tuplet", %w[note note]]],
          [["tuplet", %w[note note]], "note"]
        ]
      end
    end
  end

  it "gives each container an id from its first item" do
    ids = layer(MEILayerFixtures.tuplet_inside_beam).first.then { |beam| [beam.id, beam.children.last.id] }
    expect(ids).to eq %w[m1-beam-p1v1-b1c1 m1-tuplet-p1v1-b1c1t480]
  end

  it "builds every event through the event writer, so its extensions still decorate them" do
    allow(HeadMusic::Notation::MEI::EventWriter).to receive(:attribute_sources).and_return([MEIExtensionStubs::EveryHook])
    beam = layer(MEILayerFixtures.graces_in_beams).find { |element| element.name == "beam" }
    expect(beam.children.map { |note| note.attributes["accid.ges"] }).to eq %w[n n n]
  end
end
