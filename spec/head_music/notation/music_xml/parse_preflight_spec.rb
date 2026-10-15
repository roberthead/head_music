require "spec_helper"

# REXML expands entities lazily, so each of these parses; the preflight must
# refuse it before any text is read, and nothing may escape as a RuntimeError.
describe HeadMusic::Notation::MusicXML::ParsePreflight do
  def document_of(xml)
    HeadMusic::Notation::MusicXML::Parser.new(xml).document
  end

  def with_entities(declarations, body)
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE score-partwise [
      #{declarations}
      ]>
      <score-partwise version="4.0">#{body}</score-partwise>
    XML
  end

  let(:laughs) do
    ['<!ENTITY lol0 "lol">', *(1..9).map { |level| %(<!ENTITY lol#{level} "#{"&lol#{level - 1};" * 10}">) }].join("\n")
  end

  it "refuses a billion laughs in text" do
    expect { document_of(with_entities(laughs, "<work><work-title>&lol9;</work-title></work>")) }
      .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /declares entities/)
  end

  it "refuses a billion laughs in an attribute" do
    expect { document_of(with_entities(laughs, %(<part id="&lol9;"/>))) }
      .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /declares entities/)
  end

  it "refuses a quadratic blowup" do
    big = %(<!ENTITY big "#{"x" * 50_000}">)
    expect { document_of(with_entities(big, "<work><work-title>#{"&big;" * 1000}</work-title></work>")) }
      .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /declares entities/)
  end

  it "refuses an external entity without reading its file" do
    secret = File.join(Dir.tmpdir, "head_music_never_read_#{Process.pid}")
    expect { document_of(with_entities(%(<!ENTITY secret SYSTEM "file://#{secret}">), "<work><work-title>&secret;</work-title></work>")) }
      .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /declares entities/)
  end

  it "reads the standard partwise DOCTYPE offline, even from an unroutable address" do
    xml = musicxml_measures(note_xml("C4", 4, "whole"), doctype: MusicXMLDocuments::PARTWISE_DOCTYPE.sub("www.musicxml.org", "10.255.255.1"))
    expect(document_of(xml).parts.length).to eq 1
  end

  it "turns text past the expansion limits into a ParseError when it is read" do
    xml = musicxml_measures(note_xml("C4", 4, "whole"), header: "<work><work-title>#{"&amp;" * 20_000}</work-title></work>")
    work = document_of(xml).header("work")
    expect { HeadMusic::Notation::MusicXML::XmlReading.text(work, "work-title") }
      .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /expansion limits/)
  end
end
