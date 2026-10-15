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
    expect(measure_attributes(flow, 1)).to eq("xml:id" => "m1-measure-b1", "n" => "1")
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
end
