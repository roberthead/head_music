require "spec_helper"
require "open3"

# Validates written documents against the MusicXML 4.0 schema, run only when
# MUSICXML_XSD names a local copy of musicxml.xsd whose imports of xml.xsd
# and xlink.xsd resolve. The schema is not committed here.
describe HeadMusic::Notation::MusicXML::Writer do
  schema = ENV["MUSICXML_XSD"]

  def schema_errors(xml, schema)
    output, status = Open3.capture2e("/usr/bin/xmllint", "--noout", "--schema", schema, "-", stdin_data: xml)
    status.success? ? [] : output.lines.grep(/error/).map(&:strip)
  end

  flows = {
    "Speed the Plough" => -> { HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH) },
    "the marked melody" => -> { MarkingFixtures.marked_melody },
    "the spanned piano" => -> { MarkingFixtures.spanned_piano },
    "the timeline melody" => -> { TimelineExpressionFixtures.melody },
    "the timeline chorale" => -> { TimelineExpressionFixtures.chorale },
    **HairpinFixtures.all.to_h { |name| ["the #{name} fixture", -> { HairpinFixtures.public_send(name) }] },
    **TupletFixtures.all.to_h { |name| ["the #{name} fixture", -> { TupletFixtures.public_send(name) }] },
    **TupletGenerator::SEEDS.to_h { |seed| ["seed #{seed}", -> { TupletGenerator.flow(seed) }] }
  }

  (schema ? flows : {}).each do |name, build|
    it "writes #{name} as a valid MusicXML 4.0 document" do
      expect(schema_errors(described_class.new(build.call).to_s, schema)).to eq []
    end
  end
end
