require "spec_helper"

describe HeadMusic::Notation::MEI::Editorial do
  def document(xml)
    HeadMusic::Notation::MEI::Parser.new(%(<mei><music><body><mdiv><score>#{xml}</score></mdiv></body></music></mei>)).document
  end

  def children(xml)
    source = document(xml).sources.first
    layer = source.score.elements.to_a.find { |element| element.name == "layer" }
    source.editorial.children(layer)
  end

  it "stands for a copy of what it names, under @copyof" do
    copied = children(%(<beam xml:id="b"><note xml:id="n1" n="1"/></beam><layer><beam copyof="#b"/></layer>))
    expect(copied.map(&:name)).to eq ["beam"]
    expect(copied.first.elements.to_a.map { |note| note.attributes["n"] }).to eq ["1"]
  end

  it "clones the copy, so that no id in the index names it" do
    xml = %(<beam xml:id="b"><note xml:id="n1"/></beam><layer><beam copyof="#b"/></layer>)
    source = document(xml).sources.first
    layer = source.score.elements.to_a.find { |element| element.name == "layer" }
    copy = source.editorial.children(layer).first
    expect(source.index.element("b")).not_to equal copy
  end

  it "expands a copy once, however often it is walked" do
    source = document(%(<beam xml:id="b"><note/></beam><layer><beam copyof="b"/></layer>)).sources.first
    layer = source.score.elements.to_a.find { |element| element.name == "layer" }
    expect(source.editorial.children(layer).first).to equal source.editorial.children(layer).first
  end

  it "expands a copy inside a copy" do
    xml = %(<note xml:id="n" n="inner"/><beam xml:id="b"><note copyof="#n"/></beam><layer><beam copyof="#b"/></layer>)
    expect(children(xml).first.elements.to_a.first.attributes["n"]).to eq "inner"
  end

  it "follows a copy of a copy" do
    xml = %(<note xml:id="a" n="end"/><note xml:id="b" copyof="#a"/><layer><note copyof="#b"/></layer>)
    expect(children(xml).first.attributes["n"]).to eq "end"
  end

  it "skips a copy of an element in another file" do
    expect(children(%(<layer><note copyof="other.mei#n1"/><rest/></layer>)).map(&:name)).to eq ["rest"]
  end

  it "raises on a copy of nothing" do
    expect { children(%(<layer><note copyof="#missing"/></layer>)) }
      .to raise_error(HeadMusic::Notation::MEI::ParseError, /"missing" names no element/)
  end

  it "raises on a copy that contains itself" do
    expect { children(%(<layer><beam xml:id="b"><note/><beam copyof="#b"/></beam><beam copyof="#b"/></layer>)) }
      .to raise_error(HeadMusic::Notation::MEI::ParseError, /copies itself/)
  end

  it "raises on two elements that copy each other" do
    expect { children(%(<layer><note xml:id="a" copyof="#b"/><note xml:id="b" copyof="#a"/></layer>)) }
      .to raise_error(HeadMusic::Notation::MEI::ParseError, /copies itself/)
  end

  it "raises on runaway expansion" do
    levels = (1..12).map { |level| %(<beam xml:id="c#{level}"><beam copyof="#c#{level - 1}"/><beam copyof="#c#{level - 1}"/></beam>) }
    xml = %(<beam xml:id="c0"><note/></beam>#{levels.join}<layer><beam copyof="#c12"/></layer>)
    expect { children(xml) }.to raise_error(HeadMusic::Notation::MEI::ParseError, /expands past \d+ elements/)
  end
end
