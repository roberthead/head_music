require "spec_helper"

describe HeadMusic::Notation::MusicXML::IdentityReader do
  def flow_with(header, names: nil, part_list: nil)
    xml = musicxml_measures(note_xml("C4", 4, "whole"), header: header, names: names)
    xml = xml.sub(%r{<part-list>.*</part-list>}m, part_list) if part_list
    HeadMusic::Notation::MusicXML.parse(xml)
  end

  let(:composer) { %(<identification><creator type="composer">Clara Schumann</creator><creator type="arranger">Someone</creator></identification>) }

  describe "titles" do
    it "names the flow for its work title alone, with no Work" do
      flow = flow_with("<work><work-title>Romance</work-title></work>")
      expect([flow.name, flow.work]).to eq ["Romance", nil]
    end

    it "names the flow for its movement title, and makes the work title its Work" do
      flow = flow_with("<work><work-title>Three Romances</work-title></work><movement-title>Andante</movement-title>")
      expect([flow.name, flow.work.title]).to eq ["Andante", "Three Romances"]
    end

    it "names the flow for its movement title alone" do
      expect(flow_with("<movement-title>Andante</movement-title>").name).to eq "Andante"
    end

    it "names the flow for a title credit when nothing else does" do
      credit = "<credit page=\"1\"><credit-type>title</credit-type><credit-words>Nocturne</credit-words></credit>"
      expect(flow_with(credit).name).to eq "Nocturne"
    end

    it "prefers the work title to a title credit" do
      credit = "<credit page=\"1\"><credit-type>title</credit-type><credit-words>Nocturne</credit-words></credit>"
      expect(flow_with("<work><work-title>Romance</work-title></work>#{credit}").name).to eq "Romance"
    end

    it "takes the default name where there is no title" do
      expect(flow_with("").name).to eq HeadMusic::Content::Flow::DEFAULT_NAME
    end
  end

  describe "composers" do
    it "gives a flow with no Work the composer string" do
      expect(flow_with("<work><work-title>Romance</work-title></work>#{composer}").composer).to eq "Clara Schumann"
    end

    it "credits the composer on the Work" do
      flow = flow_with("<work><work-title>Three Romances</work-title></work><movement-title>Andante</movement-title>#{composer}")
      expect(flow.work.credits.names(:composer)).to eq ["Clara Schumann"]
    end

    it "joins several composers" do
      creators = %(<identification><creator type="composer">A</creator><creator type="composer">B</creator></identification>)
      expect(flow_with(creators).composer).to eq "A, B"
    end

    it "skips the arranger" do
      arranger = %(<identification><creator type="arranger">Someone</creator></identification>)
      expect(flow_with(arranger).composer).to be_nil
    end
  end

  describe "parts" do
    it "names each part's player for its part name, with no project" do
      player = flow_with("", names: ["Violin"]).parts.first.player
      expect([player.name, player.project]).to eq ["Violin", nil]
    end

    it "gives a part with no part name no player" do
      expect(flow_with("", names: [nil]).parts.first.player).to be_nil
    end

    it "maps the instrument sound to a catalog instrument" do
      part_list = %(<part-list><score-part id="P1"><part-name>Cl.</part-name><score-instrument id="P1-I1">) +
        %(<instrument-name>Clarinet</instrument-name><instrument-sound>wind.reed.clarinet.bflat</instrument-sound></score-instrument></score-part></part-list>)
      expect(flow_with("", part_list: part_list).parts.first.instrument.name_key).to eq :clarinet
    end

    it "gives an unmapped sound no instrument" do
      part_list = %(<part-list><score-part id="P1"><part-name>Voice</part-name><score-instrument id="P1-I1">) +
        %(<instrument-name>Voice</instrument-name><instrument-sound>voice.male</instrument-sound></score-instrument></score-part></part-list>)
      expect(flow_with("", part_list: part_list).parts.first.instrument).to be_nil
    end
  end

  describe "reading back what the writer writes" do
    let(:project) { LayoutFixtures.clarinet_project }
    let(:original) { project.flows.first }
    let(:flow) { HeadMusic::Notation::MusicXML.parse(HeadMusic::Notation::MusicXML.render(original)) }

    it "keeps the instrument" do
      expect(flow.parts.first.instrument).to eq original.parts.first.instrument
    end

    it "keeps the player's name" do
      expect(flow.parts.first.player.name).to eq "Clarinet"
    end

    it "keeps a cited work and its composer" do
      work = HeadMusic::Content::Work.new(title: "Suite").with_credit(HeadMusic::Content::Person.new(full_name: "J. S. Bach"), :composer)
      cited = HeadMusic::Content::Flow.new(name: "Gigue", work: work).tap { |gigue| gigue.add_voice.place("1:1", :whole, "C4") }
      read = HeadMusic::Notation::MusicXML.parse(HeadMusic::Notation::MusicXML.render(cited))
      expect([read.name, read.work.title, read.composer]).to eq ["Gigue", "Suite", "J. S. Bach"]
    end
  end
end
