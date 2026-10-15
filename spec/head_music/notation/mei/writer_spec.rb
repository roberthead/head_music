require "spec_helper"

describe HeadMusic::Notation::MEI::Writer do
  def tune(name)
    HeadMusic::Notation::ABC.parse("X:1\nT:#{name}\nM:4/4\nL:1/4\nK:C\nCDEF|G4|]\n")
  end

  let(:flow) { tune("Tune") }
  let(:document) { parse_mei(described_class.new([flow]).to_s) }

  it "opens with the XML declaration and the schema it validates against" do
    expect(described_class.new([flow]).to_s.lines.first(2)).to eq [
      %(<?xml version="1.0" encoding="UTF-8"?>\n),
      %(<?xml-model href="https://music-encoding.org/schema/5.1/mei-CMN.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"?>\n)
    ]
  end

  it "ends with a newline" do
    expect(described_class.new([flow]).to_s).to end_with "</mei>\n"
  end

  it "labels the mdiv with the flow's name" do
    expect(mei_attributes(document, "//mei:mdiv", "xml:id", "label")).to eq [["m1", "Tune"]]
  end

  it "holds a score of a scoreDef and a section" do
    expect(mei_elements(document, "//mei:score/*").map(&:name)).to eq %w[scoreDef section]
  end

  it "writes a measure for each bar" do
    expect(mei_attributes(document, "//mei:measure", "n")).to eq %w[1 2]
  end

  it "gives every element from the mdiv down an id" do
    expect(mei_elements_without_ids(document)).to eq []
  end

  describe "several flows" do
    let(:document) { parse_mei(described_class.new([tune("One"), tune("Two")], title: "Both").to_s) }

    it "writes an mdiv for each, numbered in order" do
      expect(mei_attributes(document, "//mei:mdiv", "xml:id", "label")).to eq [%w[m1 One], %w[m2 Two]]
    end

    it "prefixes each flow's ids with its mdiv" do
      expect(mei_attributes(document, "//mei:mdiv[2]//mei:note", "xml:id").first).to eq "m2-p1v1-b1c1"
    end

    it "keeps the first flow's ids as they are alone" do
      alone = parse_mei(described_class.new([tune("One")]).to_s)
      expect(mei_ids(document).grep(/\Am1/)).to eq mei_ids(alone)
    end

    it "titles the document with the title it is given" do
      expect(mei_element(document, "//mei:titleStmt/mei:title").text).to eq "Both"
    end
  end

  it "raises before writing anything for a flow that cannot be written" do
    empty = HeadMusic::Content::Flow.new(name: "Empty")
    empty.add_voice
    expect { described_class.new([flow, empty]).to_s }.to raise_error(HeadMusic::Notation::MEI::RenderError, /no voice events/)
  end

  it "checks the title and arranger it is given" do
    expect { described_class.new([flow], arranger: "A\u0001").to_s }
      .to raise_error(HeadMusic::Notation::MEI::RenderError, /XML forbids/)
  end
end
