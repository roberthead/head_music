require "spec_helper"
require "open3"

# Validates the documents the reader specs are built from, and the files of
# other scorewriters, against the MusicXML 4.0 schema, run only when
# MUSICXML_XSD names a local copy of musicxml.xsd whose imports of xml.xsd
# and xlink.xsd resolve without the network. The schema is not committed
# here.
describe HeadMusic::Notation::MusicXML, oracle: :musicxml_xsd do
  schema = ENV["MUSICXML_XSD"]

  def schema_errors(xml, schema)
    output, status = Open3.capture2e("/usr/bin/xmllint", "--noout", "--nonet", "--schema", schema, "-", stdin_data: xml)
    status.success? ? [] : output.lines.grep(/error/).map(&:strip)
  end

  # The hand-written shapes the reader specs lean on, each as the
  # MusicXMLDocuments helpers write it.
  documents = {
    "notes, rests, and chords" => -> { musicxml_measures(note_xml("C4", 1, "quarter") + note_xml("E4", 1, "quarter", chord: true) + rest_xml(1, "quarter") + note_xml("D4", 2, "half")) },
    "two voices on two staves" => lambda do
      musicxml_measures(
        note_xml("E5", 4, "whole", voice: "1", staff: 1) + backup_xml(4) + note_xml("C3", 4, "whole", voice: "2", staff: 2),
        attributes: opening_attributes(extra: "<staves>2</staves>", clef: nil)
      )
    end,
    "a melisma's extenders" => lambda do
      sung = %(<lyric number="1"><syllabic>single</syllabic><text>Lord</text><extend type="start"/></lyric>)
      held = ->(type) { %(<lyric number="1"><extend#{type && %( type="#{type}")}/></lyric>) }
      musicxml_measures(
        note_xml("C4", 1, "quarter", after: sung) + note_xml("D4", 1, "quarter", after: held["continue"]) +
          note_xml("E4", 1, "quarter", after: held["stop"]) + note_xml("F4", 1, "quarter", after: held[nil])
      )
    end,
    "a forward gap" => -> { musicxml_measures(note_xml("C4", 2, "half", voice: "1") + forward_xml(2, voice: "1")) },
    "a whole-measure rest" => -> { musicxml_measures(measure_rest_xml(4), note_xml("C4", 4, "whole")) },
    "a pickup" => -> { musicxml_measures([note_xml("G4", 1, "quarter"), {number: "0", implicit: true}], note_xml("C5", 4, "whole")) },
    "ties and tied notes" => lambda do
      tie = ->(type) { %(<tie type="#{type}"/>) }
      tied = ->(type) { %(<tied type="#{type}"/>) }
      musicxml_measures(note_xml("C4", 4, "whole", inside: tie["start"], notations: tied["start"]), note_xml("C4", 4, "whole", inside: tie["stop"], notations: tied["stop"]))
    end,
    "a triplet" => lambda do
      modification = "<time-modification><actual-notes>3</actual-notes><normal-notes>2</normal-notes></time-modification>"
      notes = %w[start continue stop].map do |type|
        notation = (type == "continue") ? "" : %(<tuplet type="#{type}"/>)
        note_xml("C4", 2, "eighth", after: modification, notations: notation)
      end
      musicxml_measures(notes.join + note_xml("D4", 3, "quarter") + note_xml("E4", 6, "half"), attributes: opening_attributes(divisions: 6))
    end,
    "a grace note" => -> { musicxml_measures(%(<note><grace slash="yes"/>#{pitch_xml("D4")}<type>eighth</type></note>) + note_xml("C4", 4, "whole")) },
    "dynamics and a wedge with offsets" => lambda do
      direction = ->(type, offset) { %(<direction><direction-type>#{type}</direction-type><offset>#{offset}</offset></direction>) }
      musicxml_measures(
        direction["<dynamics><p/></dynamics>", 0] + direction[%(<wedge type="crescendo"/>), -1] + note_xml("C4", 4, "whole") + direction[%(<wedge type="stop"/>), 0]
      )
    end,
    "repeats and endings" => lambda do
      barline = ->(location, inner) { %(<barline location="#{location}">#{inner}</barline>) }
      musicxml_measures(
        barline["left", %(<repeat direction="forward"/>)] + note_xml("C4", 4, "whole"),
        barline["left", %(<ending number="1" type="start"/>)] + note_xml("D4", 4, "whole") +
          barline["right", %(<ending number="1" type="stop"/><repeat direction="backward"/>)],
        barline["left", %(<ending number="2" type="start"/>)] + note_xml("E4", 4, "whole") + barline["right", %(<ending number="2" type="discontinue"/>)]
      )
    end,
    "navigation" => lambda do
      musicxml_measures(
        %(<direction><direction-type><segno/></direction-type><sound segno="s1"/></direction>) + note_xml("C4", 4, "whole"),
        note_xml("D4", 4, "whole") + %(<direction><direction-type><words>D.S.</words></direction-type><sound dalsegno="s1"/></direction>)
      )
    end,
    "lyrics" => lambda do
      lyric = %(<lyric number="1"><syllabic>begin</syllabic><text>Ky</text><elision/><text>ri</text></lyric>)
      musicxml_measures(note_xml("C4", 4, "whole", after: lyric))
    end,
    "a per-staff transposition" => lambda do
      transpose = "<transpose number=\"1\"><diatonic>-1</diatonic><chromatic>-2</chromatic></transpose>"
      musicxml_measures(note_xml("D4", 4, "whole"), attributes: opening_attributes(extra: transpose, clef: nil))
    end,
    "two parts" => -> { musicxml_document([note_xml("C5", 4, "whole")], [note_xml("C3", 4, "whole")]) }
  }

  # Files the gem commits from other scorewriters, but 41g, which leaves
  # out the part id it was written to test.
  files = Dir[File.join(MuseScoreFixtures::DIRECTORY, "**", "*.{xml,musicxml}")].sort
  invalid = %w[41g-PartNoId.xml]

  documents.each do |name, build|
    it "builds #{name} as a valid MusicXML 4.0 document" do
      expect(schema_errors(instance_exec(&build), schema)).to eq []
    end
  end

  files.each do |path|
    name = File.basename(path)
    next if invalid.include?(name)

    it "commits #{name} as a valid MusicXML document" do
      expect(schema_errors(File.read(path), schema)).to eq []
    end
  end

  it "finds the invalid files it leaves out" do
    expect(invalid - files.map { |path| File.basename(path) }).to eq []
  end
end
