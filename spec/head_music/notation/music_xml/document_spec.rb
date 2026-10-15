require "spec_helper"

describe HeadMusic::Notation::MusicXML::Document do
  def document_of(xml)
    HeadMusic::Notation::MusicXML::Parser.new(xml).document
  end

  describe "a timewise document" do
    let(:xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <score-timewise version="4.0">
          <part-list>
            <score-part id="P1"><part-name>Flute</part-name></score-part>
            <score-part id="P2"><part-name>Cello</part-name></score-part>
          </part-list>
          <measure number="0" implicit="yes">
            <part id="P1"><note><pitch><step>G</step><octave>4</octave></pitch><duration>1</duration></note></part>
            <part id="P2"><note><rest/><duration>1</duration></note></part>
          </measure>
          <measure number="1">
            <part id="P1"><note><pitch><step>C</step><octave>5</octave></pitch><duration>4</duration></note></part>
            <part id="P2"><note><pitch><step>C</step><octave>3</octave></pitch><duration>4</duration></note></part>
          </measure>
        </score-timewise>
      XML
    end
    let(:document) { document_of(xml) }

    it "is timewise" do
      expect(document).to be_timewise
    end

    it "regroups its measures into parts, in order" do
      expect(document.parts.map(&:id)).to eq %w[P1 P2]
    end

    it "gives each part every measure" do
      expect(document.parts.map { |part| part.measures.map(&:number) }).to eq [%w[0 1], %w[0 1]]
    end

    it "takes the implicit flag from the measure around each part" do
      expect(document.parts.first.measures.map(&:implicit?)).to eq [true, false]
    end

    it "reads each measure's music from its part's element" do
      expect(document.parts.last.measures.last.element.name).to eq "part"
    end

    it "finds each part's score-part" do
      expect(document.parts.map { |part| part.score_part.elements["part-name"].text }).to eq %w[Flute Cello]
    end
  end

  describe "a partwise document" do
    it "reads a measure's number and implicit flag" do
      xml = musicxml_measures([note_xml("G4", 4, "whole"), {number: "0", implicit: true}], note_xml("C5", 4, "whole"))
      expect(document_of(xml).parts.first.measures.map { |measure| [measure.number, measure.implicit?] }).to eq [["0", true], ["2", false]]
    end

    it "reads a part missing from the part-list with no score-part" do
      xml = musicxml_measures(note_xml("C4", 4, "whole"), names: [])
      expect(document_of(xml).parts.first.score_part).to be_nil
    end

    it "leaves out a part with no notes" do
      xml = musicxml_document([note_xml("C4", 4, "whole")], ["<attributes><divisions>1</divisions></attributes>"], attributes: false)
      expect(document_of(xml).parts.map(&:id)).to eq ["P1"]
    end
  end
end
