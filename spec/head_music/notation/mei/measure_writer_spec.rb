require "spec_helper"

describe HeadMusic::Notation::MEI::MeasureWriter do
  def measure(flow, bar_number)
    plan = HeadMusic::Notation::MEI::RenderPlan.new(flow)
    lines = HeadMusic::Notation::MEI::Markup.lines(described_class.new(plan).element(bar_number))
    parse_mei(%(<mei xmlns="http://www.music-encoding.org/ns/mei">#{lines.join}</mei>))
  end

  def measure_attributes(flow, bar_number)
    mei_attribute_hash(mei_element(measure(flow, bar_number), "//mei:measure"))
  end

  it "numbers the measure by its bar" do
    flow = LilyPondFixtures.rests
    expect(measure_attributes(flow, 1)).to include("xml:id" => "m1-measure-b1", "n" => "1")
  end

  it "marks a pickup bar as an upbeat" do
    flow = LilyPondFixtures.pickup_and_short_final_bar
    expect(measure_attributes(flow, 0)).to include("n" => "0", "type" => "upbeat")
  end

  it "marks a final bar the music does not fill" do
    flow = LilyPondFixtures.short_final_bar
    expect([1, 3].map { |bar| measure_attributes(flow, bar)["metcon"] }).to eq [nil, "false"]
  end

  it "writes a staff with a layer for each voice on it" do
    flow = LilyPondFixtures.rests
    expect(mei_attributes(measure(flow, 1), "//mei:staff/mei:layer", "xml:id", "n")).to eq [%w[m1-layer-b1s1l1 1]]
  end

  it "fills a bar a voice places nothing in with a measure rest" do
    flow = LilyPondFixtures.duo
    expect(mei_attributes(measure(flow, 2), "//mei:staff[@n='2']/mei:layer/*", "xml:id")).to eq ["m1-p2v1-b2c1"]
  end

  describe "a voice crossing between staves" do
    let(:flow) { LilyPondFixtures.cross_staff_piano }

    def layers(bar_number)
      mei_elements(measure(flow, bar_number), "//mei:staff").map do |staff|
        [staff.attributes["n"], staff.get_elements("layer").map { |layer| layer.attributes["n"] }]
      end
    end

    it "keeps the voice's layer number on the staff it crosses to" do
      expect([1, 2, 4].map { |bar| layers(bar) }).to eq [
        [["1", ["1"]], ["2", ["2"]]],
        [["1", %w[1 2]], ["2", []]],
        [["1", ["1"]], ["2", ["2"]]]
      ]
    end

    it "leaves the staff it leaves bare" do
      expect(mei_element(measure(flow, 2), "//mei:staff[@n='2']").children).to eq []
    end
  end

  it "ties a note across the barline where its voice crosses" do
    document = measure(LilyPondFixtures.tie_into_staff_crossing, 2)
    expect(mei_attributes(document, "//mei:staff[@n='1']/mei:layer[@n='2']/mei:note", "tie")).to eq ["t", nil]
  end

  it "leaves bare the staff of a part with no voices" do
    flow = LilyPondFixtures.rests.tap(&:add_part)
    expect(mei_element(measure(flow, 1), "//mei:staff[@n='2']").children).to eq []
  end

  describe "extensions" do
    let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nT:E\nM:2/4\nL:1/4\nK:C\nCD|EF|]\n") }
    let(:hook) { MEIExtensionStubs::EveryHook }

    it "merges the attributes of its measure sources" do
      allow(described_class).to receive(:attribute_sources).and_return([hook])
      expect([1, 2].map { |bar| measure_attributes(flow, bar)["right"] }).to eq [nil, "end"]
    end

    it "writes each control after the staves of its bar" do
      allow(described_class).to receive(:control_sources).and_return([hook])
      expect(mei_elements(measure(flow, 2), "//mei:measure/*").map(&:name)).to eq %w[staff dynam]
    end

    it "asks each control source once for every bar" do
      allow(described_class).to receive(:control_sources).and_return([hook])
      plan = HeadMusic::Notation::MEI::RenderPlan.new(flow)
      allow(plan.source(hook)).to receive(:controls).and_call_original
      described_class.new(plan).then { |writer| [1, 2].each { |bar| writer.element(bar) } }
      expect(plan.source(hook)).to have_received(:controls).once
    end

    it "builds each layer's children with its layer builder" do
      allow(described_class).to receive(:layer_builder).and_return(MEIExtensionStubs::BeamedLayer)
      expect(mei_attributes(measure(flow, 1), "//mei:layer/mei:beam/mei:note", "pname")).to eq %w[c d]
    end
  end
end
