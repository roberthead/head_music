require "spec_helper"

describe HeadMusic::Notation::MEI::IdIndex do
  subject(:index) { described_class.new }

  let(:note) { REXML::Element.new("note") }

  before { index.register("n1", note) }

  it "raises on an id used twice, naming it" do
    expect { index.register("n1", REXML::Element.new("rest"), measure: "3") }
      .to raise_error(HeadMusic::Notation::MEI::ParseError, /"n1" is used twice \(measure 3, <rest>\)/)
  end

  it "resolves a reached element with or without its #" do
    index.reach(note)
    expect([index.resolve("#n1"), index.resolve("n1")]).to all(equal(note))
  end

  it "resolves an element the walk never reached, as in a rejected reading, to nil" do
    expect(index.resolve("#n1")).to be_nil
  end

  it "resolves a reference into another file to nil" do
    expect(index.resolve("other.mei#n1")).to be_nil
  end

  it "raises on a reference that names nothing, naming the control" do
    expect { index.resolve("#n9", element: REXML::Element.new("slur")) }
      .to raise_error(HeadMusic::Notation::MEI::ParseError, /"n9" names no element \(<slur>\)/)
  end
end
