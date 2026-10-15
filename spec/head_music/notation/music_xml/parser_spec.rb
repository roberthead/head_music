require "spec_helper"

describe HeadMusic::Notation::MusicXML::Parser do
  def document_of(xml)
    described_class.new(xml).document
  end

  let(:xml) { musicxml_measures(note_xml("C4", 4, "whole")) }

  it "reads a partwise document" do
    expect(document_of(xml).parts.map(&:id)).to eq ["P1"]
  end

  describe "malformed input" do
    it "names the line of malformed XML" do
      expect { document_of(%(<?xml version="1.0"?>\n<score-partwise>\n<part></score-partwise>)) }
        .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /Malformed MusicXML.*\(line 3\)/)
    end

    it "raises on blank input" do
      expect { document_of(" \n ") }.to raise_error(HeadMusic::Notation::MusicXML::ParseError, "MusicXML input is blank")
    end

    it "raises on a declaration with no root element" do
      expect { document_of(%(<?xml version="1.0"?>\n)) }.to raise_error(HeadMusic::Notation::MusicXML::ParseError, /root/)
    end

    it "names a root that is not a score" do
      expect { document_of(%(<?xml version="1.0"?>\n<opus/>)) }
        .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /<opus> root/)
    end

    it "raises an error every reader's error class covers" do
      expect { document_of("<score-partwise>") }.to raise_error(HeadMusic::Notation::ParseError)
    end
  end

  describe "a compressed .mxl" do
    it "names the follow-up" do
      expect { document_of("PK\x03\x04\x14\x00".b) }
        .to raise_error(HeadMusic::Notation::MusicXML::UnsupportedFeatureError, /Compressed MusicXML \(\.mxl\)/)
    end
  end

  describe "encodings" do
    let(:titled) { musicxml_measures(note_xml("C4", 4, "whole"), header: "<work><work-title>Café</work-title></work>") }

    def title(xml)
      HeadMusic::Notation::MusicXML::XmlReading.text(document_of(xml).header("work"), "work-title")
    end

    it "reads UTF-8 with a byte order mark" do
      expect(title("﻿#{titled}")).to eq "Café"
    end

    it "reads a binary string, as File.binread gives" do
      expect(title(titled.b)).to eq "Café"
    end

    it "reads UTF-16 with a byte order mark" do
      utf16 = "﻿#{titled.sub('encoding="UTF-8"', 'encoding="UTF-16"')}".encode("UTF-16LE")
      expect(title(utf16.b)).to eq "Café"
    end

    it "reads big-endian UTF-16 with a byte order mark" do
      utf16 = "﻿#{titled.sub('encoding="UTF-8"', 'encoding="UTF-16"')}".encode("UTF-16BE")
      expect(title(utf16.b)).to eq "Café"
    end
  end
end
