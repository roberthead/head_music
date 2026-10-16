require "spec_helper"

describe HeadMusic::Notation::MEI::Parser do
  def document_of(xml)
    described_class.new(xml).document
  end

  def title_of(xml)
    reading = HeadMusic::Notation::MEI::XmlReading
    head = document_of(xml).sources.first.head
    reading.text(%w[fileDesc titleStmt].reduce(head) { |element, name| reading.first_child(element, name) }, "title")
  end

  let(:xml) { mei_document(mei_staff(1, mei_note("C4", "1")), head: mei_head(title: "Café")) }

  describe "malformed input" do
    it "names the line of malformed XML" do
      expect { document_of(%(<?xml version="1.0"?>\n<mei>\n<music></mei>)) }
        .to raise_error(HeadMusic::Notation::MEI::ParseError, /Malformed MEI.*\(line 3\)/)
    end

    it "raises on blank input" do
      expect { document_of(" \n ") }.to raise_error(HeadMusic::Notation::MEI::ParseError, "MEI input is blank")
    end

    it "names a root that is not MEI" do
      expect { document_of(%(<?xml version="1.0"?>\n<score-partwise/>)) }
        .to raise_error(HeadMusic::Notation::MEI::ParseError, /<score-partwise> root, not <mei>, <meiCorpus>, or <music>/)
    end

    it "raises an error every reader's error class covers" do
      expect { document_of("<mei>") }.to raise_error(HeadMusic::Notation::ParseError)
    end
  end

  describe "encodings" do
    it "reads UTF-8 with a byte order mark" do
      expect(title_of("﻿#{xml}")).to eq "Café"
    end

    it "reads a binary string, as File.binread gives" do
      expect(title_of(xml.b)).to eq "Café"
    end

    it "reads UTF-16 with a byte order mark" do
      utf16 = xml.sub(%(encoding="UTF-8"), %(encoding="UTF-16")).encode("UTF-16").b
      expect(title_of(utf16)).to eq "Café"
    end
  end

  describe "@meiversion" do
    %w[4.0.1 5.1 5.1+basic 5.1+anyStart].each do |version|
      it "reads meiversion #{version} alike" do
        expect(title_of(xml.sub(%(meiversion="5.1"), %(meiversion="#{version}")))).to eq "Café"
      end
    end
  end

  describe "#flows" do
    it "reads back each flow of a several-flow render, in order" do
      flows = %w[One Two].map do |name|
        HeadMusic::Content::Flow.new(name: name).tap { |flow| flow.add_voice.place(flow.position(1, 1, 0), :whole, "C4") }
      end
      expect(described_class.new(HeadMusic::Notation::MEI::Writer.new(flows).to_s).flows.map(&:name)).to eq %w[One Two]
    end
  end

  describe "a score with no music" do
    let(:empty) { %(<mdiv><score><scoreDef><staffGrp><staffDef n="1" lines="5"/></staffGrp></scoreDef><section/></score></mdiv>) }

    it "makes no flow of a book" do
      expect(described_class.new(xml.sub("<mdiv>", "#{empty}<mdiv>")).flows.map(&:name)).to eq ["Café"]
    end

    it "raises where no score of a book has music" do
      expect { described_class.new(xml.sub(/<mdiv>.*<\/mdiv>/m, empty)).flows }.to raise_error(HeadMusic::Notation::MEI::ParseError, /contains no music/)
    end

    it "raises as the one score" do
      expect { described_class.new(xml.sub(/<mdiv>.*<\/mdiv>/m, empty)).flow }.to raise_error(HeadMusic::Notation::MEI::ParseError, /contains no music/)
    end
  end

  describe "#flow" do
    it "names the count and points to parse_book where the body holds several scores" do
      two = xml.sub("</mdiv>", "</mdiv><mdiv><score/></mdiv>")
      expect { described_class.new(two).flow }
        .to raise_error(HeadMusic::Notation::MEI::ParseError, /holds 2 scores; MEI.parse_book/)
    end
  end
end
