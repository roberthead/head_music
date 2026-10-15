require "spec_helper"

describe HeadMusic::Notation::MEI::BeamReader do
  def eighths(*pitches, **attributes)
    pitches.each_with_index.map do |pitch, index|
      mei_note(pitch, "8", "xml:id": "n#{index + 1}", **attributes.transform_values { |values| values[index] }.compact)
    end.join
  end

  def beam(content)
    "<beam>#{content}</beam>"
  end

  def breaks(*items, **options)
    stub_const("HeadMusic::Notation::MEI::MARK_READERS", [described_class])
    flow = HeadMusic::Notation::MEI.parse(mei_document(*items, **options))
    flow.voices.map { |voice| voice.voice_events.map(&:beam_break_before) }
  end

  def bar(content, controls = "")
    mei_staff(1, content) + controls
  end

  # Each <beam> and <beamSpan> of a render, as the ids of what it holds.
  def rendered_beams(xml)
    document = REXML::Document.new(xml)
    beams = REXML::XPath.match(document, "//*[local-name()='beam']").map do |element|
      REXML::XPath.match(element, ".//*[local-name()='note' or local-name()='chord' or local-name()='rest']").map { |member| member.attributes["xml:id"] }
    end
    [beams, REXML::XPath.match(document, "//*[local-name()='beamSpan']").map { |span| span.attributes["plist"] }]
  end

  def randomly_broken(seed)
    random = Random.new(seed)
    TupletGenerator.flow(seed).tap do |flow|
      flow.voices.each { |voice| voice.voice_events.each { |event| event.beam_break_before = [nil, true, false].sample(random: random) } }
    end
  end

  let(:half) { mei_note("G4", "2") }

  describe "<beam>" do
    it "joins a beam across a beam group's start, setting nothing where the beams follow the default" do
      expect(breaks(bar(beam(eighths("C4", "D4")) + beam(eighths("E4", "F4", "G4", "A4")) + mei_note("B4", "4"))))
        .to eq [[nil, nil, nil, nil, false, nil, nil]]
    end

    it "breaks a beam inside a beam group" do
      expect(breaks(bar(eighths("C4", "D4") + beam(mei_note("E4", "8") + mei_note("F4", "8")) + half)))
        .to eq [[nil, true, nil, nil, nil]]
    end

    it "compares only notes that follow one another in a bar, and leaves a rest or an unbeamable note to the default" do
      expect(breaks(bar(eighths("C4") + mei_rest("8") + mei_note("D4", "4") + eighths("E4", "F4") + mei_note("G4", "4")), bar(eighths("A4", "B4") + mei_note("C5", "2", dots: "1"))))
        .to eq [[nil, nil, nil, nil, true, nil, nil, true, nil]]
    end

    it "reads a chord as one note" do
      chord = ->(*pitches) { %(<chord dur="8">#{pitches.map { |pitch| mei_note(pitch) }.join}</chord>) }
      expect(breaks(bar(beam(eighths("C4", "D4")) + beam(mei_note("E4", "8") + chord.call("F4", "A4") + mei_note("G4", "8")) + chord.call("B4", "D5") + mei_note("C5", "4"))))
        .to eq [[nil, nil, nil, nil, false, true, nil]]
    end

    it "gives no flag to a tie's later link, and reads the note after it" do
      content = beam(mei_note("C4", "8", tie: "i") + mei_note("C4", "8", tie: "t") + mei_note("E4", "8") + mei_note("F4", "8")) + half
      expect(breaks(bar(content))).to eq [[nil, false, nil, nil]]
    end

    it "skips grace notes" do
      content = beam(mei_note("C4", "8") + %(<note pname="a" oct="4" dur="16" grace="unacc"/>) + mei_note("D4", "8") + mei_note("E4", "8")) + mei_note("F4", "8") + half
      expect(breaks(bar(content))).to eq [[nil, nil, false, true, nil]]
    end

    it "groups by the meter in force" do
      expect(breaks(bar(beam(eighths("C4", "D4", "E4")) + eighths("F4") + beam(eighths("G4", "A4"))), score_def: mei_score_def(meter: [6, 8])))
        .to eq [[nil, nil, nil, nil, true, nil]]
    end
  end

  describe "@beam" do
    it "joins notes from i through m to t, by number" do
      expect(breaks(bar(eighths("C4", "D4", "E4", "F4", beam: ["i1", "m1", "m1", "t1"]) + eighths("G4", "A4") + mei_note("B4", "4"))))
        .to eq [[nil, nil, false, nil, nil, true, nil]]
    end

    it "pairs within a voice" do
      layers = mei_staff(1, [1, eighths("C5", "D5", "E5", "F5", beam: ["i1", "m1", "m1", "t1"]) + half], [2, eighths("C4", "D4", "E4", "F4") + half])
      expect(breaks(layers)).to eq [[nil, nil, false, nil, nil], [nil, true, nil, true, nil]]
    end
  end

  describe "<beamSpan>" do
    it "joins the notes its @plist lists" do
      expect(breaks(bar(eighths("C4", "D4", "E4", "F4") + half, %(<beamSpan staff="1" layer="1" startid="#n2" endid="#n3" plist="#n2 #n3"/>))))
        .to eq [[nil, true, false, true, nil]]
    end

    it "reads a chord tone it lists as its chord" do
      chord = %(<chord dur="8">#{mei_note("E4", "xml:id": "e4") + mei_note("G4")}</chord>)
      content = eighths("C4", "D4") + chord + mei_note("F4", "8", "xml:id": "f4") + half
      expect(breaks(bar(content, %(<beamSpan staff="1" layer="1" plist="#n2 #e4"/>)))).to eq [[nil, true, false, true, nil]]
    end
  end

  describe "round trips" do
    it "reads back the beams of every tuplet generator seed with its notes' breaks set at random" do
      failing = TupletGenerator::SEEDS.reject do |seed|
        xml = randomly_broken(seed).to_mei
        rendered_beams(HeadMusic::Notation::MEI.parse(xml).to_mei) == rendered_beams(xml)
      end
      expect(failing).to be_empty
    end

    it "reads back the beams of the fixtures that break them" do
      flows = [HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH), HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR)]
      expect(flows.map { |flow| rendered_beams(HeadMusic::Notation::MEI.parse(flow.to_mei).to_mei) }).to eq flows.map { |flow| rendered_beams(flow.to_mei) }
    end
  end
end
