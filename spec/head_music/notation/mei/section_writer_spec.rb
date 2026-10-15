require "spec_helper"

describe HeadMusic::Notation::MEI::SectionWriter do
  def section(flow)
    plan = HeadMusic::Notation::MEI::RenderPlan.new(flow)
    lines = HeadMusic::Notation::MEI::Markup.lines(described_class.new(plan).element)
    parse_mei(%(<mei xmlns="http://www.music-encoding.org/ns/mei">#{lines.join}</mei>))
  end

  def children(document, xpath = "//mei:section/*")
    mei_elements(document, xpath).map { |element| element.attributes["xml:id"] }
  end

  let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nT:S\nM:2/4\nL:1/4\nK:C\nCD|EF|GA|]\n") }

  it "writes a measure for each bar" do
    expect(children(section(flow))).to eq %w[m1-measure-b1 m1-measure-b2 m1-measure-b3]
  end

  it "writes what its sources place before a bar ahead of its measure" do
    allow(described_class).to receive(:pre_measure_sources).and_return([MEIExtensionStubs::EveryHook])
    expect(children(section(flow))).to eq %w[m1-measure-b1 m1-scoredef-b2 m1-staffdef-b2s1 m1-measure-b2 m1-measure-b3]
  end

  it "wraps the bars of each group in its element" do
    allow(described_class).to receive(:bar_group).and_return(MEIExtensionStubs::EveryHook)
    document = section(flow)
    expect([children(document), children(document, "//mei:ending/*")])
      .to eq [%w[m1-measure-b1 m1-ending-b2], %w[m1-measure-b2 m1-measure-b3]]
  end
end
