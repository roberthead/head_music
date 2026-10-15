require "spec_helper"

describe HeadMusic::Notation::MEI::IdIndex do
  subject(:index) { described_class.new }

  let(:note) { REXML::Element.new("note") }

  before { index.register("n1", note) }

  describe "an id used twice" do
    let(:rest) { REXML::Element.new("rest") }

    before do
      index.register("n1", rest, measure: "3")
      index.reach(note)
    end

    it "raises where a control's reference names it, naming the control" do
      expect { index.resolve("#n1", measure: "4", element: REXML::Element.new("slur")) }
        .to raise_error(HeadMusic::Notation::MEI::ParseError, /"n1" that a reference names is used twice \(measure 4, <slur>\)/)
    end

    it "keeps the first element for a @copyof" do
      expect(index.target("#n1")).to equal note
    end
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
