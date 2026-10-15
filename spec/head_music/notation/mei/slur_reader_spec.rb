require "spec_helper"

describe HeadMusic::Notation::MEI::SlurReader do
  def spans(*items, **options)
    stub_const("HeadMusic::Notation::MEI::MARK_READERS", [described_class])
    span_summary(HeadMusic::Notation::MEI.parse(mei_document(*items, **options)))
  end

  def quarters(*pitches, **attributes)
    pitches.each_with_index.map do |pitch, index|
      mei_note(pitch, "4", "xml:id": "n#{index + 1}", **attributes.transform_values { |values| values[index] }.compact)
    end.join
  end

  def bar(content, controls = "")
    mei_staff(1, content) + controls
  end

  describe "<slur> and <phrase>" do
    it "makes a slur between the notes it names, and a phrase mark of a <phrase>" do
      controls = %(<slur staff="1" startid="#n1" endid="#n2"/><phrase staff="1" startid="#n2" endid="#n4"/>)
      expect(spans(bar(quarters("C4", "D4", "E4", "F4"), controls))).to eq [["slur from 1:1:000 to 1:2:000", "phrase from 1:2:000 to 1:4:000"]]
    end

    it "lets a phrase end on a rest, and drops a slur there, which the voice refuses" do
      content = quarters("C4", "D4", "E4") + mei_rest("4", "xml:id": "r1")
      controls = %(<slur staff="1" startid="#n1" endid="#r1"/><phrase staff="1" startid="#n2" endid="#r1"/>)
      expect(spans(bar(content, controls))).to eq [["phrase from 1:2:000 to 1:4:000"]]
    end

    it "resolves a slur by beats where exactly one note starts at each end" do
      expect(spans(bar(quarters("C4", "D4", "E4", "F4"), %(<slur staff="1" tstamp="1" tstamp2="0m+3"/>)))).to eq [["slur from 1:1:000 to 1:3:000"]]
    end

    it "drops a slur by beats where several notes start at an end" do
      score_def = mei_score_def(clefs: [%w[G 2], %w[F 4]])
      measure = mei_staff(1, quarters("C5", "D5", "E5", "F5")) + mei_staff(2, mei_note("C3", "1")) +
        %(<slur staff="1" tstamp="1" tstamp2="0m+3"/><slur staff="1" tstamp="2" tstamp2="0m+4"/>)
      expect(spans(measure, score_def: score_def)).to eq [["slur from 1:2:000 to 1:4:000"], []]
    end

    it "ends at the note an id names, whatever starts at its beat" do
      score_def = mei_score_def(clefs: [%w[G 2], %w[F 4]])
      measure = mei_staff(1, quarters("C5", "D5", "E5", "F5")) + mei_staff(2, mei_note("C3", "1")) +
        %(<slur staff="1" tstamp="1" startid="#n1" endid="#n3"/>)
      expect(spans(measure, score_def: score_def)).to eq [["slur from 1:1:000 to 1:3:000"], []]
    end

    it "starts on the grace notes before a note when it starts on one of them" do
      content = %(<graceGrp>#{mei_note("D4", "16", "xml:id": "g1") + mei_note("E4", "16", "xml:id": "g2")}</graceGrp>) + quarters("C4", "D4", "E4", "F4")
      controls = %(<slur staff="1" startid="#g2" endid="#n1"/><slur staff="1" startid="#n2" endid="#n3"/>)
      expect(spans(bar(content, controls))).to eq [["slur from the grace notes before 1:1:000 to 1:1:000", "slur from 1:2:000 to 1:3:000"]]
    end

    it "ends a slur on a tie's later link on the tied note" do
      first = bar(mei_note("C4", "2", "xml:id": "n1") + mei_note("E4", "2", tie: "i", "xml:id": "n2"))
      second = bar(mei_note("E4", "2", tie: "t", "xml:id": "n3") + mei_note("F4", "2"), %(<slur staff="1" startid="#n1" endid="#n3"/>))
      expect(spans(first, second)).to eq [["slur from 1:1:000 to 1:3:000"]]
    end

    it "drops a slur whose ends are in different voices" do
      layers = mei_staff(1, [1, quarters("C5", "D5", "E5", "F5")], [2, mei_note("C4", "1", "xml:id": "low")])
      expect(spans(layers + %(<slur staff="1" startid="#n1" endid="#low"/><slur staff="1" startid="#n1" endid="#n2"/>)))
        .to eq [["slur from 1:1:000 to 1:2:000"], []]
    end
  end

  describe "@slur" do
    it "pairs starts and ends by number" do
      expect(spans(bar(quarters("C4", "D4", "E4", "F4", slur: ["i1", "i2", "t1", "t2"]))))
        .to eq [["slur from 1:1:000 to 1:3:000", "slur from 1:2:000 to 1:4:000"]]
    end

    it "takes a value with no number as its own number, and ends one slur before starting the next on a note" do
      expect(spans(bar(quarters("C4", "D4", "E4", "F4", slur: ["i", "i t", "t", nil]))))
        .to eq [["slur from 1:1:000 to 1:2:000", "slur from 1:2:000 to 1:3:000"]]
    end

    it "pairs within a voice" do
      layers = mei_staff(1, [1, quarters("C5", "D5", "E5", "F5", slur: ["i1", nil, "t1", nil])], [2, mei_note("C4", "2", slur: "i1") + mei_note("D4", "2", slur: "t1")])
      expect(spans(layers)).to eq [["slur from 1:1:000 to 1:3:000"], ["slur from 1:1:000 to 1:3:000"]]
    end

    it "skips a value it cannot read and an end with no start" do
      expect(spans(bar(quarters("C4", "D4", "E4", "F4", slur: ["x1", "t1", "i1", "t1"])))).to eq [["slur from 1:3:000 to 1:4:000"]]
    end
  end

  describe "the goldens" do
    it "reads back their sources' slurs and phrase marks" do
      names = %w[marked_dal_segno_al_coda grace_notes_before_downbeat triplets fourth_species]
      read = names.map { |name| span_summary(HeadMusic::Notation::MEI.parse(File.read(MEIFixtures.path(name)))) }
      expect(read).to eq names.map { |name| span_summary(MEIFixtures.source(name)) }
    end
  end

  describe "the tuplet generator" do
    it "round-trips the slurs of every seed" do
      failing = TupletGenerator::SEEDS.reject do |seed|
        source = TupletGenerator.flow(seed)
        span_summary(HeadMusic::Notation::MEI.parse(source.to_mei)) == span_summary(source)
      end
      expect(failing).to be_empty
    end
  end
end
