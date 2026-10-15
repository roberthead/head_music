require "spec_helper"

describe HeadMusic::Notation::MusicXML::SlurReader do
  def slur(type, number = nil)
    number ? %(<slur type="#{type}" number="#{number}"/>) : %(<slur type="#{type}"/>)
  end

  def quarter(pitch, *slurs, **options)
    note_xml(pitch, 1, "quarter", notations: slurs.join, **options)
  end

  def grace(pitch, *slurs)
    "<note><grace/>#{pitch_xml(pitch)}<type>16th</type>#{"<notations>#{slurs.join}</notations>" unless slurs.empty?}</note>"
  end

  def spans(*measures)
    stub_const("HeadMusic::Notation::MusicXML::MARK_READERS", [described_class])
    span_summary(parse_musicxml_flow(musicxml_measures(*measures)))
  end

  it "pairs slurs by number" do
    expect(spans(quarter("C4", slur("start", 1)) + quarter("D4", slur("start", 2)) + quarter("E4", slur("stop", 1)) + quarter("F4", slur("stop", 2))))
      .to eq [["slur from 1:1:000 to 1:3:000", "slur from 1:2:000 to 1:4:000"]]
  end

  it "takes a slur with no number as number 1" do
    expect(spans(quarter("C4", slur("start")) + quarter("D4") + quarter("E4", slur("stop", 1)) + quarter("F4")))
      .to eq [["slur from 1:1:000 to 1:3:000"]]
  end

  it "ends one slur and begins the next on one note" do
    expect(spans(quarter("C4", slur("start", 1)) + quarter("D4", slur("stop", 1), slur("start", 1)) + quarter("E4", slur("stop", 1)) + quarter("F4")))
      .to eq [["slur from 1:1:000 to 1:2:000", "slur from 1:2:000 to 1:3:000"]]
  end

  it "ends a slur stopping on a tie's later link on the tied note" do
    expect(spans(quarter("C4", slur("start", 1)) + quarter("D4") + note_xml("E4", 2, "half", inside: %(<tie type="start"/>)),
      note_xml("E4", 1, "quarter", inside: %(<tie type="stop"/>), notations: slur("stop", 1)) + note_xml("F4", 3, "half", dots: 1)))
      .to eq [["slur from 1:1:000 to 1:3:000"]]
  end

  it "reads a slur starting on a rest as a phrase" do
    expect(spans(rest_xml(1, "quarter", notations: slur("start", 1)) + quarter("D4") + quarter("E4", slur("stop", 1)) + quarter("F4")))
      .to eq [["phrase from 1:1:000 to 1:3:000"]]
  end

  it "reads a slur stopping on a rest as a phrase" do
    expect(spans(quarter("C4", slur("start", 1)) + quarter("D4") + rest_xml(2, "half", notations: slur("stop", 1))))
      .to eq [["phrase from 1:1:000 to 1:3:000"]]
  end

  it "starts a slur on a grace note from the grace notes" do
    expect(spans(quarter("C4") + grace("E4", slur("start", 1)) + quarter("D4", slur("stop", 1)) + note_xml("E4", 2, "half")))
      .to eq [["slur from the grace notes before 1:2:000 to 1:2:000"]]
  end

  it "ends a slur stopping on a grace note on its main note" do
    expect(spans(quarter("C4", slur("start", 1)) + grace("E4", slur("stop", 1)) + quarter("D4") + note_xml("E4", 2, "half")))
      .to eq [["slur from 1:1:000 to 1:2:000"]]
  end

  it "starts a slur on a grace note dropped before a rest at the rest, as a phrase" do
    expect(spans(quarter("C4") + grace("E4", slur("start", 1)) + rest_xml(1, "quarter") + note_xml("E4", 2, "half", notations: slur("stop", 1))))
      .to eq [["phrase from 1:2:000 to 1:3:000"]]
  end

  it "drops a slur from a grace note queued at the end of the part" do
    expect(spans(note_xml("C4", 4, "whole") + grace("E4", slur("start", 1)))).to eq [[]]
  end

  it "drops a stop with nothing open and a start never closed" do
    expect(spans(quarter("C4", slur("stop", 1)) + quarter("D4", slur("start", 2)) + quarter("E4") + quarter("F4"))).to eq [[]]
  end

  it "replaces an open start with a later one on its number" do
    expect(spans(quarter("C4", slur("start", 1)) + quarter("D4", slur("start", 1)) + quarter("E4", slur("stop", 1)) + quarter("F4")))
      .to eq [["slur from 1:2:000 to 1:3:000"]]
  end

  it "skips a continue" do
    expect(spans(quarter("C4", slur("start", 1)) + quarter("D4", slur("continue", 1)) + quarter("E4", slur("stop", 1)) + quarter("F4")))
      .to eq [["slur from 1:1:000 to 1:3:000"]]
  end

  it "drops a slur whose ends are in different voices" do
    expect(spans(quarter("C4", slur("start", 1), voice: "1") + quarter("D4", voice: "1") + note_xml("E4", 2, "half", voice: "1") +
      backup_xml(4) + quarter("G3", voice: "2") + quarter("A3", slur("stop", 1), voice: "2") + note_xml("B3", 2, "half", voice: "2")))
      .to eq [[], []]
  end

  it "drops a slur the voice refuses rather than raising" do
    expect(spans(quarter("C4", slur("start", 1), slur("stop", 1)) + quarter("D4") + note_xml("E4", 2, "half"))).to eq [[]]
  end

  it "pairs slurs within a part only" do
    stub_const("HeadMusic::Notation::MusicXML::MARK_READERS", [described_class])
    xml = musicxml_document([note_xml("C4", 4, "whole", notations: slur("start", 1))], [note_xml("C3", 4, "whole", notations: slur("stop", 1))])
    expect(span_summary(parse_musicxml_flow(xml))).to eq [[], []]
  end

  describe "round trips" do
    def round_trip(flow)
      parse_musicxml_flow(HeadMusic::Notation::MusicXML.render(flow))
    end

    %i[spanned_melody crossing_spans touching_slurs touching_slurs_on_tied_note phrases_on_split_rest].each do |name|
      it "brings back the spans of #{name}" do
        original = MarkingFixtures.public_send(name)
        expect_same_spans(original, round_trip(original))
      end
    end

    it "brings back a phrase between two notes as a slur" do
      expect(span_summary(round_trip(MarkingFixtures.spanned_piano)))
        .to eq [["slur from 1:1:000 to 4:1:000"], ["slur from 1:1:000 to 2:1:000"]]
    end

    it "brings back the slur from grace notes" do
      original = TupletFixtures.grace_notes_before_downbeat
      expect_same_spans(original, round_trip(original))
    end

    it "brings back the slurs of the LilyPond tuplets and grace notes" do
      original = HeadMusic::Notation::LilyPond.parse(File.read("spec/fixtures/notation/lily_pond/tuplets_and_grace_notes.ly"))
      expect_same_spans(original, round_trip(original))
    end

    TupletGenerator::SEEDS.each do |seed|
      it "brings back the slurs of tuplet seed #{seed}" do
        original = TupletGenerator.flow(seed)
        expect_same_spans(original, round_trip(original))
      end
    end
  end
end
