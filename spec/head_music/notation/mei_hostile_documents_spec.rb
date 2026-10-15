require "spec_helper"

describe HeadMusic::Notation::MEI do
  hostile_values = ["", " ", "-1", "0", "99999999", "1e400", "1_0", "+3", "NaN", "x" * 1000].freeze

  def outcome
    yield
    :read
  rescue HeadMusic::Notation::MEI::ParseError => error
    error.class
  end

  describe HeadMusic::Notation::MEI::AttributeValues do
    bounds = {"tstamp" => {count: 4}, "tstamp2" => {bars_left: 3, count: 4}}

    described_class::READERS.each_key do |name|
      it "reads @#{name} or raises a ParseError for every hostile value" do
        element = REXML::Element.new("note")
        outcomes = hostile_values.map do |value|
          outcome { described_class.parse(name, value, element: element, measure: "1", **bounds.fetch(name, {})) }
        end
        expect(outcomes - [:read]).to all(be <= HeadMusic::Notation::MEI::ParseError)
      end
    end

    it "names the attribute, value, and element" do
      expect { described_class.parse("oct", "99999999", element: REXML::Element.new("note"), measure: "4") }
        .to raise_error(HeadMusic::Notation::MEI::ParseError, %r{Unreadable @oct "99999999" \(measure 4, <note>\)})
    end

    {
      %w[pname h] => HeadMusic::Notation::MEI::ParseError,
      %w[dots 1000000] => HeadMusic::Notation::MEI::UnsupportedFeatureError,
      %w[num 0] => HeadMusic::Notation::MEI::ParseError,
      %w[numbase 0] => HeadMusic::Notation::MEI::ParseError,
      %w[meter.unit 0] => HeadMusic::Notation::MEI::ParseError,
      %w[meter.unit 3] => HeadMusic::Notation::MEI::UnsupportedFeatureError,
      %w[meter.count 3+2] => HeadMusic::Notation::MEI::UnsupportedFeatureError,
      %w[keysig mixed] => HeadMusic::Notation::MEI::UnsupportedFeatureError,
      %w[keysig 99s] => HeadMusic::Notation::MEI::ParseError,
      %w[keysig 8s] => HeadMusic::Notation::MEI::ParseError,
      %w[trans.semi 99999999] => HeadMusic::Notation::MEI::ParseError,
      %w[accid 1qs] => HeadMusic::Notation::MEI::UnsupportedFeatureError,
      %w[dur 512] => HeadMusic::Notation::MEI::UnsupportedFeatureError,
      %w[dur 0m+2.5] => HeadMusic::Notation::MEI::ParseError
    }.each do |(name, value), error_class|
      it "raises #{error_class.name.split("::").last} on @#{name}=#{value.inspect}" do
        expect { described_class.parse(name, value) }.to raise_error(error_class)
      end
    end

    it "bounds the bars a @tstamp2 reaches" do
      expect { described_class.parse("tstamp2", "99999999m+1", bars_left: 3, count: 4) }
        .to raise_error(HeadMusic::Notation::MEI::ParseError, /tstamp2/)
    end

    it "reads a @tstamp2 of the beat after the last" do
      expect(described_class.parse("tstamp2", "2m+5", bars_left: 3, count: 4)).to eq [2, 5]
    end
  end

  describe "documents" do
    # Attributes whose readers later steps put to use.
    pending_attributes = %w[numbase trans.diat trans.semi tstamp2]

    note_attributes = %w[pname pname.ges oct oct.ges dur dots accid accid.ges staff grace cue]
    score_def_attributes = %w[key.pname keysig key.sig key.mode meter.count meter.unit meter.sym midi.bpm]
    clef_attributes = %w[shape line dis dis.place]
    contexts = [
      *note_attributes, *score_def_attributes, *clef_attributes, *clef_attributes.map { |name| "clef.#{name}" },
      "dur.default", "sig", "mode", "count", "unit", "sym", "n", "lines", "midi.instrnum", "num",
      "metcon", "tstamp", "mm", "mm.unit", "mm.dots"
    ]

    def attributes_xml(attributes)
      attributes.map { |key, text| %( #{key}="#{text}") }.join
    end

    def whole_note
      mei_staff(1, mei_note("C4", "1"))
    end

    def with_score_def(inside: "", staff_def: mei_staff_def(1), **attributes)
      [whole_note, {score_def: %(<scoreDef#{attributes_xml(attributes.transform_keys(&:to_s))}>#{inside}<staffGrp>#{staff_def}</staffGrp></scoreDef>)}]
    end

    def meter_attributes
      {"keysig" => "0", "meter.count" => "4", "meter.unit" => "4"}
    end

    # A document whose one hostile value is an attribute of that name.
    def document_with(name, value)
      case name
      when "dur.default" then [mei_staff(1, %(<note pname="c" oct="4"/>)), {score_def: mei_score_def(extra: %( dur.default="#{value}"))}]
      when "sig" then with_score_def(:inside => %(<keySig sig="#{value}"/>), "meter.count" => "4", "meter.unit" => "4")
      when "mode" then with_score_def(:inside => %(<keySig sig="1s" mode="#{value}"/>), "meter.count" => "4", "meter.unit" => "4")
      when "count", "unit" then with_score_def(inside: "<meterSig#{attributes_xml({"count" => "4", "unit" => "4"}.merge(name => value))}/>")
      when "sym" then with_score_def(inside: %(<meterSig sym="#{value}"/>))
      when "n" then [%(<staff n="#{value}"><layer n="#{value}">#{mei_note("C4", "1")}</layer></staff>)]
      when "lines" then with_score_def(staff_def: mei_staff_def(1, attributes: %( lines="#{value}")).sub(%( lines="5"), ""), **meter_attributes)
      when "midi.instrnum" then with_score_def(staff_def: mei_staff_def(1, inside: %(<instrDef midi.instrnum="#{value}"/>)), **meter_attributes)
      when "num" then [mei_staff(1, %(<multiRest num="#{value}"/>))]
      when "metcon" then [[whole_note, %(<measure n="2" metcon="#{value}">#{mei_staff(1, mei_note("C4", "2"))}</measure>)]]
      when "tstamp", "mm", "mm.unit", "mm.dots"
        [whole_note + "<tempo#{attributes_xml({"tstamp" => "1", "mm" => "60"}.merge(name => value))}/>"]
      when *note_attributes_list then [mei_staff(1, "<note#{attributes_xml({"pname" => "c", "oct" => "4", "dur" => "1"}.merge(name => value))}/>")]
      when /\Aclef\./ then with_score_def(staff_def: mei_staff_def(1, clef: nil, attributes: attributes_xml({"clef.shape" => "G", "clef.line" => "2"}.merge(name => value))), **meter_attributes)
      when "shape", "line", "dis", "dis.place"
        with_score_def(staff_def: mei_staff_def(1, clef: nil, inside: "<clef#{attributes_xml({"shape" => "G", "line" => "2"}.merge(name => value))}/>"), **meter_attributes)
      else with_score_def(**meter_attributes, name => value)
      end
    end

    define_method(:note_attributes_list) { note_attributes }

    it "has a document for every attribute the reader reads" do
      expect(contexts + pending_attributes).to match_array(HeadMusic::Notation::MEI::AttributeValues::READERS.keys)
    end

    contexts.each do |name|
      it "parses or raises a ParseError for every hostile @#{name}" do
        outcomes = hostile_values.map do |value|
          items, options = document_with(name, value)
          outcome { described_class.parse(mei_document(*Array(items), **options.to_h)) }
        end
        expect(outcomes - [:read]).to all(be <= HeadMusic::Notation::MEI::ParseError)
      end
    end

    def parse(xml)
      described_class.parse(xml)
    end

    describe "a duplicate xml:id" do
      let(:bars) { [mei_staff(1, %(<note xml:id="n" pname="c" oct="4" dur="1"/>)), %(<measure xml:id="n" n="2">#{mei_staff(1, mei_note("D4", "1"))}</measure>)] }

      it "reads where nothing refers to it, as music21's test file reuses ids" do
        expect(parse(mei_document(*bars)).voices.first.voice_events.map(&:to_s)).to eq ["whole C4 at 1:1:000", "whole D4 at 2:1:000"]
      end
    end

    it "refuses a @copyof cycle" do
      xml = mei_document(%(<measure xml:id="m" n="1"><staff n="1" copyof="#m"/></measure>), %(<measure copyof="#m"/>))
      expect { described_class::Parser.new(xml).document.sources.first.then { |source| walk(source) } }
        .to raise_error(described_class::ParseError, /copies itself/)
    end

    it "refuses nesting deeper than 256 elements without overflowing the stack" do
      deep = "<beam>" * 50_000 + "</beam>" * 50_000
      expect { parse(mei_document(mei_staff(1, deep))) }.to raise_error(described_class::ParseError, /deeper than 256/)
    end

    {"a title" => "&b;", "an attribute" => %(<rend type="&b;">x</rend>)}.each do |place, title|
      it "refuses declared entities, as a billion laughs in #{place} declares" do
        laughs = %(<!DOCTYPE mei [<!ENTITY a "aaaaaaaaaa"><!ENTITY b "&a;&a;&a;&a;&a;&a;&a;&a;&a;&a;">]>)
        xml = mei_document(mei_staff(1, mei_note("C4", "1")), head: mei_head(title: title)).sub("<mei xmlns", "#{laughs}\n<mei xmlns")
        expect { parse(xml) }.to raise_error(described_class::ParseError, /declares entities/)
      end
    end

    it "raises a ParseError on text past REXML's expansion limits" do
      expect { parse(mei_document(whole_note, head: mei_head(title: "&amp;" * 20_000))) }
        .to raise_error(described_class::ParseError, /expansion limits/)
    end

    it "keeps an <xi:include> and an <?xml-model?> inert" do
      xml = mei_document(mei_staff(1, mei_note("C4", "1")))
        .sub("<music>", %(<music><xi:include xmlns:xi="http://www.w3.org/2001/XInclude" href="file:///etc/passwd"/>))
      expect(parse(%(<?xml-model href="http://example.com/x.rng"?>\n) + xml.sub(/\A<\?xml[^>]*>\n/, ""))).to be_a HeadMusic::Content::Flow
    end

    def walk(source)
      stack = [source.score]
      until stack.empty?
        element = stack.pop
        stack.concat(source.editorial.children(element))
      end
    end
  end
end
