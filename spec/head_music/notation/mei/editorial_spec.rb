require "spec_helper"

describe HeadMusic::Notation::MEI::Editorial do
  subject(:editorial) { described_class.new(index, budget: 1000) }

  let(:index) { HeadMusic::Notation::MEI::IdIndex.new }

  def names(xml)
    root = REXML::Document.new("<layer>#{xml}</layer>").root
    editorial.children(root).map { |element| element.attributes["n"] || element.name }
  end

  it "keeps an element's own children" do
    expect(names(%(<note n="1"/><rest n="2"/>))).to eq %w[1 2]
  end

  it "takes an app's lemma" do
    expect(names(%(<app><rdg><note n="r"/></rdg><lem><note n="l"/></lem></app>))).to eq ["l"]
  end

  it "takes an app's first reading where it has no lemma" do
    expect(names(%(<app><rdg><note n="a"/></rdg><rdg><note n="b"/></rdg></app>))).to eq ["a"]
  end

  %w[corr reg expan].each do |name|
    it "takes a choice's <#{name}>" do
      rejected = {"corr" => "sic", "reg" => "orig", "expan" => "abbr"}.fetch(name)
      expect(names(%(<choice><#{rejected}><note n="x"/></#{rejected}><#{name}><note n="y"/></#{name}></choice>))).to eq ["y"]
    end
  end

  it "takes a choice's <corr> over its <reg>, and its <reg> over its <expan>, in any order" do
    choice = %(<choice><expan><note n="expan"/></expan><reg><note n="reg"/></reg><corr><note n="corr"/></corr></choice>)
    expect([names(choice), names(choice.sub(%r{<corr>.*</corr>}, ""))]).to eq [["corr"], ["reg"]]
  end

  it "takes a choice's first child where it names none of them" do
    expect(names(%(<choice><unclear><note n="1"/></unclear><unclear><note n="2"/></unclear></choice>))).to eq ["1"]
  end

  it "takes a substitution's addition" do
    expect(names(%(<subst><del><note n="old"/></del><add><note n="new"/></add></subst>))).to eq ["new"]
  end

  %w[supplied add unclear restore damage].each do |name|
    it "keeps the contents of <#{name}>" do
      expect(names(%(<#{name}><note n="1"/><note n="2"/></#{name}>))).to eq %w[1 2]
    end
  end

  it "skips a deletion" do
    expect(names(%(<note n="1"/><del><note n="2"/></del><note n="3"/>))).to eq %w[1 3]
  end

  it "resolves markup nested in markup" do
    expect(names(%(<app><lem><supplied><choice><sic/><corr><note n="deep"/></corr></choice></supplied></lem></app>))).to eq ["deep"]
  end

  it "marks what it keeps as reached and what it rejects as not" do
    root = REXML::Document.new(%(<layer><app><lem><note n="l"/></lem><rdg><note n="r"/></rdg></app></layer>)).root
    kept = editorial.children(root).first
    rejected = root.elements.to_a.first.elements.to_a.last.elements.to_a.first
    expect([index.reached?(kept), index.reached?(rejected)]).to eq [true, false]
  end
end
