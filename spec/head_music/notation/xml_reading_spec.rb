require "spec_helper"

describe HeadMusic::Notation::XmlReading do
  let(:stub_error) do
    Class.new(HeadMusic::Notation::ParseError) do
      attr_reader :measure

      def initialize(message, measure: nil)
        @measure = measure
        super(message)
      end
    end
  end

  let(:reading) { described_class.for(stub_error, format: "MEI") }
  let(:element) { REXML::Document.new(%(<note pname=" c "><a>1</a><!-- x --><b> two </b>text<b>three</b></note>)).root }

  it "reads the stripped text of a child" do
    expect(reading.text(element, "b")).to eq "two"
  end

  it "reads a stripped attribute" do
    expect(reading.attribute(element, "pname")).to eq "c"
  end

  it "finds the first child of a name, skipping text and comments" do
    expect(reading.first_child(element, "b").text).to eq " two "
  end

  it "finds every child of a name" do
    expect(reading.children(element, "b").map(&:text)).to eq [" two ", "three"]
  end

  it "returns nil where there is no such child" do
    expect(reading.first_child(element, "c")).to be_nil
  end

  it "raises its own error class for an unreadable number, with the location" do
    expect { reading.integer("x", "@oct", measure: "4") }.to raise_error(stub_error) { |error| expect(error.measure).to eq "4" }
  end

  it "refuses an exponent" do
    expect { reading.rational("1e9", "@num") }.to raise_error(stub_error, /Unreadable @num "1e9"/)
  end

  it "names its format when text passes the expansion limits" do
    xml = %(<mei><title>#{"&amp;" * 20_000}</title></mei>)
    title = REXML::Document.new(xml).root
    expect { reading.text(title, "title") }.to raise_error(stub_error, /\AMEI text exceeds the entity expansion limits/)
  end

  it "includes its readers privately" do
    host = Class.new.include(reading)
    expect(host.new.respond_to?(:text)).to be false
  end

  it "keeps formats apart" do
    other = described_class.for(HeadMusic::Notation::MusicXML::ParseError, format: "MusicXML")
    expect { other.integer("x", "<octave>") }.to raise_error(HeadMusic::Notation::MusicXML::ParseError)
  end
end
