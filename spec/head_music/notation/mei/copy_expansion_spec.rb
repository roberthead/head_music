require "spec_helper"

describe HeadMusic::Notation::MEI::CopyExpansion do
  subject(:expansion) { described_class.new(index, budget: budget) }

  let(:index) { HeadMusic::Notation::MEI::IdIndex.new }
  let(:budget) { 10 }
  let(:root) { REXML::Document.new(xml).root }

  before do
    root.each_recursive { |element| index.register(element.attributes["xml:id"], element) if element.attributes["xml:id"] }
  end

  def element(id)
    index.target("##{id}")
  end

  def copier
    root.elements.to_a.last
  end

  context "with a copy of a beam" do
    let(:xml) { %(<score><beam xml:id="b"><note n="1"/></beam><beam copyof="#b"/></score>) }

    it "answers an element with no @copyof as itself" do
      expect(expansion.effective(element("b"))).to equal element("b")
    end

    it "answers a clone of what a @copyof names" do
      copy = expansion.effective(copier)
      expect([copy.name, copy.elements.to_a.map { |note| note.attributes["n"] }]).to eq ["beam", ["1"]]
      expect(copy).not_to equal element("b")
    end

    it "expands a copy once, however often it is asked for" do
      expect(expansion.effective(copier)).to equal expansion.effective(copier)
    end

    context "with a budget smaller than the copy" do
      let(:budget) { 1 }

      it "raises" do
        expect { expansion.effective(copier) }.to raise_error(HeadMusic::Notation::MEI::ParseError, /expands past 1 elements/)
      end
    end
  end

  context "with a copy inside a copy" do
    let(:xml) { %(<score><note xml:id="n" n="inner"/><beam xml:id="b"><note copyof="#n"/></beam><beam copyof="#b"/></score>) }

    it "expands the inner copy too" do
      expect(expansion.effective(copier).elements.to_a.first.attributes["n"]).to eq "inner"
    end
  end

  context "with a copy within its own copy" do
    let(:xml) { %(<score><beam xml:id="b"><beam copyof="#b"/></beam><beam copyof="#b"/></score>) }

    it "raises" do
      expect { expansion.effective(copier) }.to raise_error(HeadMusic::Notation::MEI::ParseError, /copies itself/)
    end
  end

  context "with a copy of something in another file" do
    let(:xml) { %(<score><beam copyof="other.mei#b"/></score>) }

    it "answers nil" do
      expect(expansion.effective(copier)).to be_nil
    end
  end
end
