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
    def parse(xml)
      described_class.parse(xml)
    end

    it "refuses a duplicate xml:id" do
      xml = mei_document(mei_staff(1, %(<note xml:id="n" pname="c" oct="4" dur="1"/>)), %(<measure xml:id="n" n="2"/>))
      expect { parse(xml) }.to raise_error(described_class::ParseError, /"n" is used twice/)
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
