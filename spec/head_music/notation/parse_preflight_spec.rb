require "spec_helper"

describe HeadMusic::Notation::ParsePreflight do
  let(:stub_error) do
    Class.new(HeadMusic::Notation::ParseError) do
      def initialize(message, **)
        super(message)
      end
    end
  end
  let(:includes) do
    <<~XML
      <?xml version="1.0"?>
      <?xml-model href="file://#{secret}" type="application/xml"?>
      <mei xmlns:xi="http://www.w3.org/2001/XInclude"><xi:include href="file://#{secret}"/></mei>
    XML
  end
  let(:secret) { File.join(Dir.tmpdir, "head_music_never_read_#{Process.pid}") }

  def check(xml, **options)
    described_class.check!(REXML::Document.new(xml), roots: %w[mei music], format: "MEI", error_class: stub_error, **options)
  end

  def nest(depth)
    "<mei>#{"<a>" * (depth - 1)}#{"</a>" * (depth - 1)}</mei>"
  end

  it "accepts a document with a listed root" do
    expect(check("<music><body/></music>")).to be_nil
  end

  it "names an unlisted root and the roots it takes" do
    expect { check("<score/>") }.to raise_error(stub_error, "MEI input has a <score> root, not <mei> or <music>")
  end

  it "lists three or more roots with commas" do
    expect { described_class.check!(REXML::Document.new("<x/>"), roots: %w[a b c], format: "F", error_class: stub_error) }
      .to raise_error(stub_error, "F input has a <x> root, not <a>, <b>, or <c>")
  end

  it "raises on a document with no root" do
    expect { described_class.check!(REXML::Document.new, roots: %w[mei], format: "MEI", error_class: stub_error) }
      .to raise_error(stub_error, "MEI input has no root element")
  end

  it "refuses declared entities, naming them" do
    xml = %(<!DOCTYPE mei [<!ENTITY a "x"><!ENTITY b "y">]><mei>&a;</mei>)
    expect { check(xml) }.to raise_error(stub_error, "MEI input declares entities (a, b)")
  end

  it "refuses an external entity without reading its file" do
    xml = %(<!DOCTYPE mei [<!ENTITY secret SYSTEM "file://#{secret}">]><mei>&secret;</mei>)
    expect { check(xml) }.to raise_error(stub_error, /declares entities \(secret\)/)
  end

  it "leaves an XInclude and an xml-model instruction inert" do
    expect(check(includes)).to be_nil
  end

  it "accepts nesting at the cap" do
    expect(check(nest(256))).to be_nil
  end

  it "refuses nesting past the cap" do
    expect { check(nest(257)) }.to raise_error(stub_error, "MEI input nests elements deeper than 256")
  end

  it "takes another cap" do
    expect { check(nest(4), max_depth: 3) }.to raise_error(stub_error, /deeper than 3/)
  end

  it "refuses a 50,000-deep nest with the error class, not a SystemStackError" do
    expect { check(nest(50_000)) }.to raise_error(stub_error, /deeper than 256/)
  end
end
