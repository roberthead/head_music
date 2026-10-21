require "spec_helper"

describe HeadMusic::Notation::MusicXML::FermataReader do
  def parse(xml)
    HeadMusic::Notation::MusicXML.parse(xml)
  end

  def fermatas(flow)
    flow.fermatas.map { |fermata| [fermata.from.to_s, fermata.to.to_s] }
  end

  def quarter(pitch, fermata: nil, **options)
    note_xml(pitch, 1, "quarter", notations: fermata.to_s, **options)
  end

  let(:fermata) { %(<fermata type="upright"/>) }

  it "reads a fermata on a note" do
    flow = parse(musicxml_measures(quarter("C4") + quarter("D4") + quarter("E4", fermata: fermata) + quarter("F4")))
    expect(fermatas(flow)).to eq [["1:3:000", "1:4:000"]]
  end

  it "reads a fermata of any shape, upright or inverted" do
    shapes = ["<fermata>angled</fermata>", "<fermata>square</fermata>", %(<fermata type="inverted"/>), "<fermata/>"]
    flow = parse(musicxml_measures(shapes.map { |shape| quarter("C4", fermata: shape) }.join))
    expect(fermatas(flow).length).to eq 4
  end

  it "reads a fermata on a rest" do
    flow = parse(musicxml_measures(note_xml("C4", 2, "half") + rest_xml(2, "half", notations: fermata)))
    expect(fermatas(flow)).to eq [["1:3:000", "2:1:000"]]
  end

  it "reads a fermata on a whole-measure rest" do
    rest = %(<note><rest measure="yes"/><duration>4</duration><notations>#{fermata}</notations></note>)
    flow = parse(musicxml_measures(note_xml("C4", 4, "whole"), rest))
    expect(fermatas(flow)).to eq [["2:1:000", "3:1:000"]]
  end

  it "reads a fermata on any tone of a chord" do
    chord = note_xml("C4", 4, "whole") + note_xml("E4", 4, "whole", chord: true, notations: fermata)
    expect(fermatas(parse(musicxml_measures(chord)))).to eq [["1:1:000", "2:1:000"]]
  end

  it "reads a fermata on a tie's later link from that link" do
    first = note_xml("C4", 4, "whole", inside: %(<tie type="start"/>), notations: %(<tied type="start"/>))
    later = note_xml("C4", 2, "half", inside: %(<tie type="stop"/>), notations: %(<tied type="stop"/>#{fermata})) + note_xml("D4", 2, "half")
    expect(fermatas(parse(musicxml_measures(first, later)))).to eq [["2:1:000", "2:3:000"]]
  end

  it "skips a fermata on a grace note" do
    grace = %(<note><grace/>#{pitch_xml("D4")}<type>eighth</type><notations>#{fermata}</notations></note>)
    expect(parse(musicxml_measures(grace + note_xml("C4", 4, "whole"))).fermatas).to be_empty
  end

  it "reads marks in two parts that sound together as one fermata" do
    soprano = [quarter("C5") + quarter("D5") + note_xml("E5", 2, "half", notations: fermata)]
    bass = [quarter("C3") + quarter("D3") + quarter("E3") + quarter("F3", fermata: fermata)]
    expect(fermatas(parse(musicxml_document(soprano, bass)))).to eq [["1:4:000", "2:1:000"]]
  end

  it "reads a fermata on a barline as one on the events that end there" do
    barline = %(<barline location="right"><fermata type="upright"/></barline>)
    flow = parse(musicxml_measures(quarter("C4") + quarter("D4") + note_xml("E4", 2, "half") + barline, note_xml("F4", 4, "whole")))
    expect(fermatas(flow)).to eq [["1:3:000", "2:1:000"]]
  end

  it "reads the fermatas of the LilyPond test suite's notations file, one on each of five quarter notes" do
    flow = parse(File.binread(File.join(MuseScoreFixtures::DIRECTORY, "lilypond_test_suite", "32a-Notations.xml")))
    expect(fermatas(flow)).to eq [
      ["1:1:000", "1:2:000"], ["1:2:000", "1:3:000"], ["1:3:000", "1:4:000"], ["1:4:000", "2:1:000"], ["2:1:000", "2:2:000"]
    ]
  end
end
