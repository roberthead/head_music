require "spec_helper"

describe HeadMusic::Notation::MusicXML::TempoReader do
  def parse(xml)
    HeadMusic::Notation::MusicXML.parse(xml)
  end

  def direction_xml(*types, offset: nil, sound: nil)
    [
      "<direction>",
      types.map { |type| "<direction-type>#{type}</direction-type>" }.join,
      offset && "<offset>#{offset}</offset>",
      sound && %(<sound tempo="#{sound}"/>),
      "</direction>"
    ].compact.join
  end

  def words(text)
    "<words>#{text}</words>"
  end

  def metronome(per_minute, unit = "quarter", dots: 0)
    "<metronome><beat-unit>#{unit}</beat-unit>#{"<beat-unit-dot/>" * dots}<per-minute>#{per_minute}</per-minute></metronome>"
  end

  def dashes(type, number = 1)
    %(<dashes type="#{type}" number="#{number}"/>)
  end

  def quarters(*pitches)
    pitches.map { |pitch| note_xml(pitch, 1, "quarter") }.join
  end

  def tempo(beat, bpm, text: nil, metronome_mark: true)
    HeadMusic::Rudiment::Tempo.new(beat, bpm, text: text, metronome_mark: metronome_mark)
  end

  def ramps(flow)
    flow.tempo_ramps.map { |ramp| [ramp.from.to_s, ramp.to.to_s, ramp.to_tempo&.beats_per_minute, ramp.text] }
  end

  let(:whole_c) { note_xml("C4", 4, "whole") }

  describe "a tempo mark" do
    it "reads words and a metronome mark as a tempo with text" do
      flow = parse(musicxml_measures(direction_xml(words("Allegro"), metronome(132), sound: 132) + whole_c))
      expect(flow.tempo).to eq tempo("quarter", 132, text: "Allegro")
    end

    it "prefers the metronome mark to the sound" do
      flow = parse(musicxml_measures(direction_xml(metronome(60, "half"), sound: 100) + whole_c))
      expect(flow.tempo).to eq tempo("half", 60)
    end

    it "reads a dotted beat" do
      flow = parse(musicxml_measures(direction_xml(metronome(60, "quarter", dots: 1)) + whole_c))
      expect(flow.tempo).to eq tempo("dotted quarter", 60)
    end

    it "reads a sound alone as quarter notes per minute" do
      expect(parse(musicxml_measures(%(<sound tempo="90"/>) + whole_c)).tempo).to eq tempo("quarter", 90)
    end

    it "reads words beside a sound as tempo text whose number was not written" do
      flow = parse(musicxml_measures(direction_xml(words("Meno mosso"), sound: 96) + whole_c))
      expect(flow.tempo).to eq tempo("quarter", 96, text: "Meno mosso", metronome_mark: false)
    end

    it "reads words alone that begin with a named tempo as tempo text" do
      flow = parse(musicxml_measures(direction_xml(words("Allegro ma non troppo")) + whole_c))
      expect(flow.tempo).to eq HeadMusic::Rudiment::Tempo.for_text("Allegro ma non troppo")
    end

    it "drops other words alone" do
      flow = parse(musicxml_measures(direction_xml(words("Meno mosso")) + whole_c, direction_xml(words("dolce")) + whole_c))
      expect([flow.tempo, flow.tempo_changes]).to eq [tempo("quarter", 120), {}]
    end

    it "reads words and a metronome mark written apart at one moment together" do
      flow = parse(musicxml_measures(direction_xml(words("Andante")) + direction_xml(metronome(72)) + whole_c))
      expect(flow.tempo).to eq tempo("quarter", 72, text: "Andante")
    end

    it "skips a metronome mark equating two beats, reading the sound instead" do
      modulation = "<metronome><beat-unit>quarter</beat-unit><beat-unit>half</beat-unit></metronome>"
      expect(parse(musicxml_measures(direction_xml(modulation, sound: 80) + whole_c)).tempo).to eq tempo("quarter", 80)
    end

    it "skips a metronome mark whose number is not one" do
      expect(parse(musicxml_measures(direction_xml(metronome("c. 120"), sound: 116) + whole_c)).tempo).to eq tempo("quarter", 116)
    end

    it "reads a change at a later downbeat" do
      flow = parse(musicxml_measures(whole_c, direction_xml(words("Adagio"), metronome(60)) + whole_c))
      expect(flow.tempo_changes).to eq(2 => tempo("quarter", 60, text: "Adagio"))
    end

    it "refuses an unreadable sound tempo" do
      expect { parse(musicxml_measures(%(<sound tempo="fast"/>) + whole_c)) }
        .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /Unreadable tempo "fast" \(measure 1 of part P1\)/)
    end
  end

  describe "a ramp" do
    it "runs from its word to the stop of its dashes" do
      flow = parse(musicxml_measures(quarters("C4", "D4") + direction_xml(words("rit."), dashes("start")) + quarters("E4", "F4"), quarters("G4") + direction_xml(dashes("stop")) + quarters("A4", "B4", "C5")))
      expect(ramps(flow)).to eq [["1:3:000", "2:2:000", nil, "rit."]]
    end

    it "takes the sound at its end, anywhere in a bar, as its target" do
      ending = direction_xml(dashes("stop"), sound: 80)
      flow = parse(musicxml_measures(direction_xml(words("rit."), dashes("start")) + whole_c, quarters("C4") + ending + quarters("D4", "E4", "F4")))
      expect(ramps(flow)).to eq [["1:1:000", "2:2:000", 80.0, "rit."]]
    end

    it "takes a metronome mark at its end as its target" do
      flow = parse(musicxml_measures(direction_xml(words("accel."), dashes("start")) + whole_c, direction_xml(dashes("stop"), metronome(144)) + whole_c))
      expect([ramps(flow), flow.tempo_ramps.first.to_tempo]).to eq [[["1:1:000", "2:1:000", 144.0, "accel."]], tempo("quarter", 144)]
    end

    it "ends at the next tempo where it has no dashes" do
      flow = parse(musicxml_measures(direction_xml(words("rall.")) + whole_c, whole_c, direction_xml(metronome(60)) + whole_c))
      expect(ramps(flow)).to eq [["1:1:000", "3:1:000", 60.0, "rall."]]
    end

    it "is not ended by the stop of other dashes" do
      cresc = direction_xml(words("cresc."), dashes("start", 2))
      flow = parse(musicxml_measures(direction_xml(words("rit."), dashes("start")) + cresc + whole_c, direction_xml(dashes("stop", 2)) + whole_c))
      expect(ramps(flow)).to eq [["1:1:000", "3:1:000", nil, "rit."]]
    end

    it "is placed by its offset" do
      flow = parse(musicxml_measures(direction_xml(words("rit."), offset: 2) + whole_c, whole_c))
      expect(ramps(flow)).to eq [["1:3:000", "3:1:000", nil, "rit."]]
    end
  end

  describe "an \"a tempo\"" do
    it "restores the tempo, the sound beside it only playing it" do
      flow = parse(musicxml_measures(direction_xml(words("rit.")) + whole_c, direction_xml(words("a tempo"), sound: 120) + whole_c))
      a_tempos = flow.a_tempos.map { |a_tempo| [a_tempo.position.to_s, a_tempo.text] }
      expect([ramps(flow), a_tempos, flow.tempo_changes]).to eq [[["1:1:000", "2:1:000", nil, "rit."]], [["2:1:000", "a tempo"]], {}]
    end
  end

  it "reads the tempo marks of any part" do
    flow = parse(musicxml_document([whole_c, whole_c], [whole_c, direction_xml(metronome(72)) + whole_c]))
    expect(flow.tempo_changes).to eq(2 => tempo("quarter", 72))
  end
end
