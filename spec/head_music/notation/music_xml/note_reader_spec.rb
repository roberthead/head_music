require "spec_helper"

describe HeadMusic::Notation::MusicXML::NoteReader do
  it "refuses a <note> with no <pitch>, <unpitched>, or <rest>, naming the measure" do
    xml = musicxml_measures("<note><duration>4</duration><type>whole</type></note>")
    expect { HeadMusic::Notation::MusicXML.parse(xml) }
      .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /A <note> has no <pitch>, <unpitched>, or <rest> \(measure 1 of part P1\)/)
  end

  it "refuses a grace note with none of them" do
    xml = musicxml_measures("<note><grace/><type>eighth</type></note>" + note_xml("C4", 4, "whole"))
    expect { HeadMusic::Notation::MusicXML.parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::ParseError, /has no <pitch>/)
  end
end
