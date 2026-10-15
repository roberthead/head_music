require "spec_helper"
require "open3"

# Validates rendered MEI against the MEI 5.1 CMN schema, run only when
# MEI_SCHEMA names a local copy of mei-CMN.rng. The schema is not committed
# here.
describe HeadMusic::Notation::MEI do
  schema = ENV["MEI_SCHEMA"]

  def schema_errors(xml, schema)
    output, status = Open3.capture2e("xmllint", "--noout", "--nonet", "--relaxng", schema, "-", stdin_data: xml)
    status.success? ? [] : output.lines.reject { |line| line.include?("validates") }.map(&:strip)
  end

  before { skip "set MEI_SCHEMA to a local copy of mei-CMN.rng" unless schema }

  MEIHelpers.sample_flows.each do |name, build|
    next if MEIHelpers::REFUSED_SAMPLES.key?(name)

    it "renders #{name} as a valid MEI 5.1 document" do
      expect(schema_errors(described_class.render(instance_exec(&build)), schema)).to eq []
    end
  end

  it "renders a document of several flows as valid MEI" do
    xml = described_class::Writer.new([LilyPondFixtures.duo, LilyPondFixtures.rests], title: "Two").to_s
    expect(schema_errors(xml, schema)).to eq []
  end

  it "renders credits and a transposed render as valid MEI" do
    flow = LilyPondFixtures.piano_and_melody
    flow.work = HeadMusic::Content::Work.new(title: "Work").with_credit("Ann", :composer).with_credit("Bo", :lyricist)
    expect(schema_errors(described_class.render(flow, arranger: %w[Cy Di], transposed: true), schema)).to eq []
  end

  it "renders labels, instruments, and roles as valid MEI" do
    flow = LilyPondFixtures.piano_and_melody.tap(&:add_part)
    flow.parts.each_with_index { |part, index| part.player = HeadMusic::Content::Player.new(name: "Player #{index}") }
    expect(schema_errors(described_class.render(flow), schema)).to eq []
  end

  it "renders what every extension hook adds as valid MEI" do
    register_every_mei_hook
    flow = HeadMusic::Notation::ABC.parse("X:1\nT:Hooks\nM:2/4\nL:1/4\nK:C\n{B}CD|[EG]F|]\n")
    expect(schema_errors(described_class.render(flow), schema)).to eq []
  end
end
