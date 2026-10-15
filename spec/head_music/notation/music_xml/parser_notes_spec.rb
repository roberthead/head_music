require "spec_helper"

describe HeadMusic::Notation::MusicXML::Parser do
  def parse(xml)
    described_class.new(xml).flow
  end

  def events(flow)
    flow.voices.first.voice_events.map(&:to_s)
  end

  describe "the writer's golden tune" do
    subject(:flow) { parse(HeadMusic::Notation::MusicXML.render(HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH))) }

    it "returns a flow" do
      expect(flow).to be_a HeadMusic::Content::Flow
    end

    it "reads the meter" do
      expect(flow.meter.to_s).to eq "4/4"
    end

    it "reads the key" do
      expect(flow.key_signature.to_s).to eq "1 sharp"
    end

    it "reads every note the writer wrote" do
      expect(events(flow)).to eq events(HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH))
    end
  end

  describe "pitches and rests" do
    let(:flow) do
      parse(
        musicxml_measures(note_xml("C4", 1, "quarter") + note_xml("F#4", 1, "quarter") + rest_xml(1, "quarter") + note_xml("Bb3", 1, "quarter"))
      )
    end

    it "reads each pitch as written, and rests" do
      expect(events(flow)).to eq ["quarter C4 at 1:1:000", "quarter F♯4 at 1:2:000", "quarter rest at 1:3:000", "quarter B♭3 at 1:4:000"]
    end

    it "spells a double flat" do
      expect(events(parse(musicxml_measures(note_xml("Bbb4", 4, "whole"))))).to eq ["whole B𝄫4 at 1:1:000"]
    end

    it "refuses a microtonal alter" do
      xml = musicxml_measures(note_xml("C4", 4, "whole").sub("<octave>", "<alter>0.5</alter><octave>"))
      expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::UnsupportedFeatureError, /Microtonal.*\(measure 1 of part P1\)/)
    end
  end

  describe "values and divisions" do
    it "reads a dotted value" do
      xml = musicxml_measures(note_xml("C4", 3, "half", dots: 1) + note_xml("D4", 1, "quarter"))
      expect(events(parse(xml)).first).to eq "dotted half C4 at 1:1:000"
    end

    it "reads durations at the divisions in force" do
      xml = musicxml_measures(note_xml("C4", 12, "half") + note_xml("D4", 6, "quarter") + note_xml("E4", 3, "eighth") * 2,
        attributes: opening_attributes(divisions: 6))
      expect(events(parse(xml)).map { |event| event.split.first }).to eq %w[half quarter eighth eighth]
    end

    it "takes a value from the duration where there is no type" do
      expect(events(parse(musicxml_measures(note_xml("C4", 3) + note_xml("D4", 1))))).to eq ["dotted half C4 at 1:1:000", "quarter D4 at 1:4:000"]
    end

    it "ignores a duration within one division of its type" do
      xml = musicxml_measures(note_xml("C4", "15.5", "half") + note_xml("D4", "16.5", "half"), attributes: opening_attributes(divisions: 8))
      expect(events(parse(xml))).to eq ["half C4 at 1:1:000", "half D4 at 1:3:000"]
    end

    it "raises where a duration disagrees with its type by more than a division" do
      xml = musicxml_measures(note_xml("C4", 3, "quarter") + note_xml("D4", 1, "quarter"))
      expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::ParseError, /disagrees.*\(measure 1 of part P1\)/)
    end

    it "raises on a duration with no divisions in force, naming the measure" do
      xml = musicxml_measures([note_xml("C4", 4, "whole"), {number: "7"}], attributes: "<attributes><time><beats>4</beats><beat-type>4</beat-type></time></attributes>")
      expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::ParseError, "A <duration> has no <divisions> in force (measure 7 of part P1)")
    end

    it "raises on an unreadable duration" do
      expect { parse(musicxml_measures(note_xml("C4", "four", "whole"))) }
        .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /Unreadable <duration> "four"/)
    end

    it "raises on a note type it has no value for" do
      expect { parse(musicxml_measures(note_xml("C4", 4, "1024th"))) }
        .to raise_error(HeadMusic::Notation::MusicXML::UnsupportedFeatureError, /1024th/)
    end
  end

  describe "an empty score" do
    it "raises" do
      xml = musicxml_measures("", attributes: opening_attributes)
      expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::ParseError, /no music/)
    end
  end

  describe "elements the reader skips" do
    let(:flow) do
      measure = "<harmony><root><root-step>C</root-step></root><kind>major</kind></harmony>" +
        note_xml("C4", 2, "half", after: "<notehead>diamond</notehead>", notations: "<technical><fingering>1</fingering><up-bow/></technical>") +
        "<figured-bass><figure><figure-number>6</figure-number></figure><duration>2</duration></figured-bass>" +
        note_xml("E4", 2, "half", notations: "<technical><down-bow/><fingering>3</fingering></technical>")
      xml = musicxml_measures(measure)
        .sub("<part-list>", %(<part-list><part-group type="start" number="1"><group-symbol>bracket</group-symbol></part-group>))
        .sub("</part-list>", %(<part-group type="stop" number="1"/></part-list>))
      parse(xml)
    end

    it "reads the notes around them" do
      expect(events(flow)).to eq ["half C4 at 1:1:000", "half E4 at 1:3:000"]
    end

    it "keeps the music whole, a <figured-bass> <duration> moving nothing" do
      expect_music_whole(flow)
    end
  end
end
