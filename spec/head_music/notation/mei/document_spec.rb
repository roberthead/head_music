require "spec_helper"

describe HeadMusic::Notation::MEI::Document do
  def sources_of(xml)
    HeadMusic::Notation::MEI::Parser.new(xml).document.sources
  end

  def score(label)
    %(<mdiv label="#{label}"><score><scoreDef/></score></mdiv>)
  end

  def mei(body, head: "<meiHead/>")
    %(<mei>#{head}<music><body>#{body}</body></music></mei>)
  end

  it "never reads an incipit's score in the head" do
    head = "<meiHead><workList><work><incip><score><scoreDef/></score></incip></work></workList></meiHead>"
    expect(sources_of(mei(score("one"), head: head)).length).to eq 1
  end

  it "descends nested mdivs in document order" do
    body = %(<mdiv label="outer">#{score("first")}<mdiv>#{score("second")}</mdiv></mdiv>#{score("third")})
    expect(sources_of(mei(body)).map { |source| source.mdiv.attributes["label"] }).to eq %w[first second third]
  end

  it "descends the music of a group" do
    xml = %(<mei><music><group><music label="a"><body>#{score("x")}</body></music><music><body>#{score("y")}</body></music></group></music></mei>)
    expect(sources_of(xml).map(&:labels)).to eq [["a"], []]
  end

  it "reads each document of a corpus with its own head, else the corpus's" do
    corpus = %(<meiCorpus><meiHead><fileDesc/></meiHead>#{mei(score("a"))}<mei><music><body>#{score("b")}</body></music></mei></meiCorpus>)
    expect(sources_of(corpus).map { |source| source.head.elements.size }).to eq [0, 1]
  end

  it "reads a <music> root" do
    expect(sources_of(%(<music><body>#{score("a")}</body></music>)).length).to eq 1
  end

  it "reads a score straight in <music>, as MEI 2013 allowed and music21's test file writes, as one division" do
    expect(sources_of(%(<mei><music label="Old"><score><scoreDef/></score></music></mei>)).map { |source| source.score.name }).to eq ["score"]
  end

  it "reads a single part as a score" do
    sources = sources_of(mei(%(<mdiv><parts><part><scoreDef/></part></parts></mdiv>)))
    expect(sources.map { |source| source.score.name }).to eq ["part"]
  end

  it "refuses several parts" do
    expect { sources_of(mei(%(<mdiv><parts><part/><part/></parts></mdiv>))) }
      .to raise_error(HeadMusic::Notation::MEI::UnsupportedFeatureError, /<parts> of 2 <part>s/)
  end

  it "raises on a document with no music" do
    expect { sources_of("<mei><meiHead/></mei>") }.to raise_error(HeadMusic::Notation::MEI::ParseError, /no <music>/)
  end

  it "raises on a body with no score" do
    expect { sources_of(mei("<mdiv/>")) }.to raise_error(HeadMusic::Notation::MEI::ParseError, /no <score> or <part>/)
  end

  describe "notation types" do
    %w[mensur ligature neume nc tabGrp].each do |name|
      it "refuses a <#{name}> for the whole document, naming its measure" do
        xml = mei(%(<mdiv><score><section><measure n="7"><staff><layer><#{name}/></layer></staff></measure></section></score></mdiv>))
        expect { sources_of(xml) }
          .to raise_error(HeadMusic::Notation::MEI::UnsupportedFeatureError, /<#{name}> notation.*measure 7/)
      end
    end

    %w[mensural mensural.white neume tab.guitar].each do |type|
      it "refuses notationtype #{type}" do
        xml = mei(%(<mdiv><score><scoreDef><staffGrp><staffDef n="1" notationtype="#{type}"/></staffGrp></scoreDef></score></mdiv>))
        expect { sources_of(xml) }.to raise_error(HeadMusic::Notation::MEI::UnsupportedFeatureError, /notationtype/)
      end
    end

    it "reads notationtype cmn" do
      xml = mei(%(<mdiv><score><scoreDef><staffGrp><staffDef n="1" notationtype="cmn"/></staffGrp></scoreDef></score></mdiv>))
      expect(sources_of(xml).length).to eq 1
    end
  end
end
