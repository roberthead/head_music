require "spec_helper"

describe HeadMusic::Notation::MEI::Ids do
  subject(:ids) { described_class.new(2) }

  let(:flow) { HeadMusic::Content::Flow.new(meter: "4/4") }

  it "names the mdiv by its number" do
    expect(ids.mdiv).to eq "m2"
  end

  describe "#event" do
    it "keys an event by part, voice, bar, and count" do
      expect(ids.event(1, 2, flow.position(3, 2))).to eq "m2-p1v2-b3c2"
    end

    it "adds the tick and subtick only where there are any" do
      expect(ids.event(1, 1, flow.position(3, 2, 480, 7))).to eq "m2-p1v1-b3c2t480s7"
    end

    it "writes a pickup bar as bar 0" do
      expect(ids.event(1, 1, flow.position(0, 3))).to eq "m2-p1v1-b0c3"
    end

    it "writes a bar before it with an m for its sign" do
      expect(ids.event(1, 1, flow.position(-1, 1))).to eq "m2-p1v1-bm1c1"
    end
  end

  it "suffixes the later links of a tied chain" do
    expect([ids.link("m2-p1v1-b1c1", 0), ids.link("m2-p1v1-b1c1", 2)]).to eq ["m2-p1v1-b1c1", "m2-p1v1-b1c1-k2"]
  end

  it "suffixes chord members from 1" do
    expect(ids.chord_member("m2-p1v1-b1c1", 0)).to eq "m2-p1v1-b1c1-h1"
  end

  it "suffixes grace notes from 1" do
    expect(ids.grace("m2-p1v1-b1c1", 1)).to eq "m2-p1v1-b1c1-g2"
  end

  it "keys other elements by kind and key" do
    expect(ids.container("layer", "#{ids.staff_key(3, 2)}l1")).to eq "m2-layer-b3s2l1"
  end

  it "names a one-off element by its kind" do
    expect(ids.container("section")).to eq "m2-section"
  end

  it "refuses a kind that would make an invalid id" do
    expect { ids.container("Staff Group") }.to raise_error(ArgumentError, /not a valid id/)
  end

  it "names a child of an element" do
    expect(ids.child("m2-p1v1-b1c1", "verse", 2)).to eq "m2-p1v1-b1c1-verse2"
  end

  it "keys an owner by part, and by voice where there is one" do
    expect([ids.owner_key(3), ids.owner_key(3, 1)]).to eq %w[p3 p3v1]
  end
end
