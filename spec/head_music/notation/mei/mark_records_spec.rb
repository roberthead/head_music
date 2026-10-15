require "spec_helper"

describe HeadMusic::Notation::MEI::MarkRecords do
  def recorded(*items, **options)
    MEIMarkRecorder.parse(mei_document(*items, **options))
  end

  def events(*items, **options)
    recorded(*items, **options).of(HeadMusic::Notation::MEI::EventRecord)
  end

  def measures(*items, **options)
    recorded(*items, **options).of(HeadMusic::Notation::MEI::MeasureRecord)
  end

  describe "the hooks" do
    let(:recorder) { recorded(mei_staff(1, mei_note("C4", "1")) + %(<dir staff="1" tstamp="1">x</dir>), mei_staff(1, mei_note("D4", "1"))) }

    it "sees each measure, then its events, then its controls, and applies once after every record" do
      expect(recorder.hooks).to eq %i[measure event control measure event apply]
    end

    it "applies to the flow the reader built" do
      expect(recorder.flow.voices.first.voice_events.map(&:to_s)).to eq ["whole C4 at 1:1:000", "whole D4 at 2:1:000"]
    end
  end

  describe "EventRecord" do
    let(:mixed_bar) { mei_staff(1, %(<chord dur="4">#{mei_note("C4") + mei_note("E4")}</chord>) + mei_rest("4") + %(<space dur="2"/>)) }

    it "is one per note, chord, rest, whole-bar rest, and space, in document order, chord tones after their chord" do
      records = events(mixed_bar, mei_staff(1, "<mRest/>"), mei_staff(1, mei_note("G4", "1")))
      expect(records.map { |record| [record.kind, record.chord_member?, record.bar_number, record.measure, record.staff] }).to eq [
        [:chord, false, 1, "1", 1], [:note, true, 1, "1", 1], [:note, true, 1, "1", 1], [:rest, false, 1, "1", 1],
        [:space, false, 1, "1", 1], [:m_rest, false, 2, "2", 1], [:note, false, 3, "3", 1]
      ]
    end

    it "names the part, the voice, and the voice event each was placed as, a chord tone's being its chord's" do
      record = events(mei_staff(1, %(<chord dur="1">#{mei_note("C4") + mei_note("E4")}</chord>))).last
      expect([record.part, record.voice, record.voice_event.to_s]).to eq [record.voice.part, record.part.voices.first, "whole C4 E4 at 1:1:000"]
    end

    it "gives a tie's later link its chain's event and its own onset" do
      bars = [mei_staff(1, mei_note("C4", "2") + mei_note("E4", "2", tie: "i")), mei_staff(1, mei_note("E4", "4", tie: "t") + mei_rest("2", dots: "1"))]
      record = events(*bars)[2]
      expect([record.continuation?, record.voice_event.to_s, record.bar_number, record.onset]).to eq [true, "half tied to quarter E4 at 1:3:000", 2, 0]
    end

    it "gives a grace note its main note's event and its place among that note's grace notes" do
      bar = %(<graceGrp>#{mei_note("D4", "16") + mei_note("E4", "16")}</graceGrp>) + mei_note("F4", "1")
      expect(events(mei_staff(1, bar)).first(2).map { |record| [record.grace?, record.grace_index, record.voice_event.to_s] })
        .to eq [[true, 0, "whole F4 at 1:1:000"], [true, 1, "whole F4 at 1:1:000"]]
    end

    it "gives a grace note dropped before a rest no voice event" do
      record = events(mei_staff(1, %(<note pname="d" oct="4" dur="16" grace="unacc"/>) + mei_rest("1"))).first
      expect([record.grace?, record.voice_event, record.grace_index]).to eq [true, nil, nil]
    end

    it "gives a whole-bar rest the rest its bar was filled with, and none in a bar the voice is tacet in" do
      bars = [mei_staff(1, "<mRest/>"), mei_staff(1, mei_note("C4", "1")), mei_staff(1, "<mRest/>"), mei_staff(1, mei_note("D4", "1"))]
      expect(events(*bars).map { |record| record.voice_event&.to_s }).to eq [nil, "whole C4 at 2:1:000", "whole rest at 3:1:000", "whole D4 at 4:1:000"]
    end

    it "gives none for a layer no voice reads" do
      staves = mei_staff(1, [1, mei_note("C5", "1")]) + mei_staff(2, [1, "<mRest/>"], [2, mei_note("C3", "1")])
      score_def = mei_score_def(staff_grp: %(<staffGrp><staffGrp symbol="brace"><label>Piano</label>#{mei_staff_def(1)}#{mei_staff_def(2, clef: %w[F 4])}</staffGrp></staffGrp>))
      expect(events(staves, score_def: score_def).map(&:kind)).to eq %i[note note]
    end
  end

  describe "MeasureRecord" do
    it "is one per measure, a <multiRest> having one" do
      records = measures(mei_staff(1, mei_note("C4", "1")), mei_staff(1, %(<multiRest num="3"/>)), mei_staff(1, mei_note("D4", "1")))
      expect(records.map { |record| [record.bar_number, record.measure, record.last?] }).to eq [[1, "1", false], [2, "2", false], [5, "3", true]]
    end

    it "takes the passes of the <ending> it is in" do
      bar = mei_staff(1, mei_note("C4", "1"))
      endings = ['<ending n="1">', '<ending n="1-2" label="1., 2.">', '<ending n="1, 3">', '<ending label="4.">', "<ending>"]
        .each_with_index.map { |tag, index| %(#{tag}<measure n="#{index + 2}">#{bar}</measure></ending>) }
      expect(measures(bar, *endings).map(&:ending_passes)).to eq [nil, [1], [1, 2], [1, 3], [4], [5]]
    end

    it "reads a dashed @n as a range where its @label lists no passes" do
      bar = mei_staff(1, mei_note("C4", "1"))
      expect(measures(bar, %(<ending n="1-3"><measure n="2">#{bar}</measure></ending>)).last.ending_passes).to eq [1, 2, 3]
    end

    it "says a measure that the next one completes ends inside its bar" do
      bars = [mei_staff(1, mei_note("C4", "1")), mei_staff(1, mei_note("C4", "2")), %(<measure n="3" metcon="false">#{mei_staff(1, mei_note("D4", "2"))}</measure>), mei_staff(1, mei_note("E4", "1"))]
      expect(measures(*bars).map { |record| [record.bar_number, record.mid_bar?] }).to eq [[1, false], [2, true], [2, false], [3, false]]
    end
  end
end
