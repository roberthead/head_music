require "spec_helper"

# What a layout displays is a rendering fact. An override changes the title in
# every format it has a field for and changes nothing in the project.
describe HeadMusic::Content::Layout do
  let(:project) { LayoutFixtures.suite }
  let(:flute) { project.players.first }
  let(:flow) { project.flows.first }

  describe "a title override on a single-flow layout" do
    subject(:layout) do
      project.add_layout(kind: :part, flows: [flow], players: [flute], title_override: "Aubade")
    end

    it "changes the ABC title field" do
      expect(layout.to_abc).to include "T:Aubade\n"
    end

    it "changes the LilyPond header title" do
      expect(layout.to_lilypond).to include %(title = "Aubade")
    end

    it "changes the MusicXML work title" do
      expect(xpath_text(parse_musicxml(layout.to_musicxml), "//work/work-title")).to eq "Aubade"
    end

    it "leaves the flow's own name alone" do
      layout.to_abc
      layout.to_lilypond
      layout.to_musicxml
      expect(flow.name).to eq "I"
    end

    it "gives the flow no movement title of its own" do
      expect(layout.to_musicxml).not_to include "<movement-title>"
    end
  end

  describe "a multi-flow layout" do
    subject(:layout) { project.add_layout(kind: :part, players: [flute]) }

    it "titles the document with the project's name" do
      expect(layout.to_lilypond).to include %(title = "Suite")
    end

    it "prefers the one work every movement cites" do
      work = HeadMusic::Content::Work.new(title: "Sonata in C", catalog_number: "Op. 1")
      project.flows.each { |flow| flow.work = work }
      expect(layout.title).to eq "Sonata in C"
    end

    it "keeps the project's name when the movements cite different works" do
      project.flows.first.work = HeadMusic::Content::Work.new(title: "Sonata in C")
      expect(layout.title).to eq "Suite"
    end

    it "keeps each movement's own name in LilyPond" do
      expect(layout.to_lilypond.scan(/piece = "(\w+)"/).flatten).to eq %w[I III]
    end

    it "keeps each movement's own name in MusicXML" do
      titles = layout.to_musicxml_documents.map { |xml| xpath_text(parse_musicxml(xml), "//movement-title") }
      expect(titles).to eq %w[I III]
    end

    it "numbers the movements from one" do
      numbers = layout.to_musicxml_documents.map { |xml| xpath_text(parse_musicxml(xml), "//movement-number") }
      expect(numbers).to eq %w[1 2]
    end

    it "titles every MusicXML movement with the document's title" do
      titles = layout.to_musicxml_documents.map { |xml| xpath_text(parse_musicxml(xml), "//work/work-title") }
      expect(titles).to eq %w[Suite Suite]
    end

    it "keeps each movement's own name in ABC, which has no book title field" do
      expect(layout.to_abc.scan(/^T:(\w+)$/).flatten).to eq %w[I III]
    end
  end

  describe "a title override on a multi-flow layout" do
    subject(:layout) { project.add_layout(kind: :part, players: [flute], title_override: "Flute Book") }

    it "titles the document" do
      expect(layout.to_lilypond).to include %(title = "Flute Book")
    end

    it "leaves the movements named as they were" do
      expect(layout.to_lilypond.scan(/piece = "(\w+)"/).flatten).to eq %w[I III]
    end
  end
end
