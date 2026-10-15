require "spec_helper"
require "rexml/document"

describe HeadMusic::Notation::MusicXML::BeamReader do
  def eighth(pitch, *beams, **options)
    note_xml(pitch, 1, "eighth", after: beam_xml(*beams), **options)
  end

  def sixteenth(pitch, *beams)
    note_xml(pitch, Rational(1, 2), "16th", after: beam_xml(*beams))
  end

  def beam_xml(*beams)
    beams.each_with_index.map { |type, index| %(<beam number="#{index + 1}">#{type}</beam>) if type }.join
  end

  def breaks(*measures, **options)
    stub_const("HeadMusic::Notation::MusicXML::MARK_READERS", [described_class])
    flow = parse_musicxml_flow(musicxml_measures(*measures, attributes: opening_attributes(divisions: 2), **options))
    flow.voices.map { |voice| voice.voice_events.map(&:beam_break_before) }
  end

  it "sets no flag where the beams follow the default grouping" do
    expect(breaks(eighth("C4", "begin") + eighth("D4", "end") + eighth("E4", "begin") + eighth("F4", "end") + note_xml("G4", 4, "half")))
      .to eq [[nil, nil, nil, nil, nil]]
  end

  it "joins a beam across a beam group's start" do
    expect(breaks(eighth("C4", "begin") + eighth("D4", "continue") + eighth("E4", "continue") + eighth("F4", "end") + note_xml("G4", 4, "half")))
      .to eq [[nil, nil, false, nil, nil]]
  end

  it "breaks a beam inside a beam group" do
    expect(breaks(eighth("C4") + eighth("D4") + eighth("E4", "begin") + eighth("F4", "end") + note_xml("G4", 4, "half")))
      .to eq [[nil, true, nil, nil, nil]]
  end

  it "reads only the primary beam" do
    expect(breaks(sixteenth("C4", "begin", "begin") + sixteenth("D4", "continue", "end") + sixteenth("E4", "continue", "begin") +
      sixteenth("F4", "end", "end") + note_xml("G4", 6, "half", dots: 1)))
      .to eq [[nil, nil, nil, nil, nil]]
  end

  it "leaves notes next to a rest or an unbeamable note to the default" do
    expect(breaks(eighth("C4") + rest_xml(1, "eighth") + note_xml("D4", 2, "quarter") + eighth("E4", "begin") + eighth("F4", "end") + note_xml("G4", 2, "quarter")))
      .to eq [[nil, nil, nil, nil, nil, nil]]
  end

  it "gives no flag to a tie's later link, and reads the note after it" do
    expect(breaks(eighth("C4", "begin", inside: %(<tie type="start"/>)) + eighth("C4", "continue", inside: %(<tie type="stop"/>)) +
      eighth("E4", "continue") + eighth("F4", "end") + note_xml("G4", 4, "half")))
      .to eq [[nil, false, nil, nil]]
  end

  it "skips chord tones and grace notes" do
    grace = "<note><grace/>#{pitch_xml("A4")}<type>16th</type>#{beam_xml("begin")}</note>"
    expect(breaks(eighth("C4", "begin") + eighth("E4", "begin", chord: true) + grace + eighth("D4", "continue") + eighth("E4", "continue") +
      eighth("F4", "end") + note_xml("G4", 4, "half")))
      .to eq [[nil, nil, false, nil, nil]]
  end

  it "compares only notes that follow one another in a bar" do
    expect(breaks(eighth("C4") + eighth("D4") + eighth("E4") + eighth("F4") + note_xml("G4", 3, "quarter", dots: 1) + eighth("A4", "begin"),
      eighth("B4", "end") + eighth("C5") + note_xml("D5", 6, "half", dots: 1)))
      .to eq [[nil, true, nil, true, nil, nil, nil, true, nil]]
  end

  it "groups by the meter in force" do
    expect(breaks(eighth("C4", "begin") + eighth("D4", "continue") + eighth("E4", "end") + eighth("F4", "begin") + eighth("G4", "continue") + eighth("A4", "end"),
      attributes: opening_attributes(divisions: 2, beats: 6, beat_type: 8)))
      .to eq [[nil, nil, nil, nil, nil, nil]]
  end

  describe "round trips" do
    def beams(xml)
      REXML::Document.new(xml).get_elements("//note").map do |note|
        note.get_elements("beam").map { |beam| "#{beam.attributes["number"]} #{beam.text}" }
      end
    end

    def expect_same_beams(flow)
      rendered = HeadMusic::Notation::MusicXML.render(flow)
      expect(beams(HeadMusic::Notation::MusicXML.render(parse_musicxml_flow(rendered)))).to eq beams(rendered)
    end

    def overridden(flow, random)
      flow.voices.flat_map(&:voice_events).each do |voice_event|
        voice_event.beam_break_before = [true, false].sample(random: random) if random.rand < 0.4
      end
      flow
    end

    it "brings back the beams of the marked melody" do
      expect_same_beams(MarkingFixtures.marked_melody)
    end

    it "brings back the beams of Bach's first invention" do
      expect_same_beams(HeadMusic::Notation::LilyPond.parse(File.read("spec/fixtures/notation/lily_pond/bach_invention_01.ly")))
    end

    TupletFixtures.all.each do |name|
      it "brings back the beams of #{name}" do
        expect_same_beams(TupletFixtures.public_send(name))
      end
    end

    TupletGenerator::SEEDS.each do |seed|
      it "brings back the beams of tuplet seed #{seed} with beam breaks overridden" do
        expect_same_beams(overridden(TupletGenerator.flow(seed), Random.new(seed)))
      end
    end
  end
end
