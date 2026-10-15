require "spec_helper"

describe HeadMusic::Notation::MusicXML::TimelineReader do
  def parse(xml)
    HeadMusic::Notation::MusicXML.parse(xml)
  end

  def round_trip(flow)
    parse(HeadMusic::Notation::MusicXML.render(flow))
  end

  let(:whole_c) { note_xml("C4", 4, "whole") }

  def key_attributes(fifths, mode = nil)
    "<attributes><key><fifths>#{fifths}</fifths>#{mode && "<mode>#{mode}</mode>"}</key></attributes>"
  end

  def tempo_direction(bpm, offset: nil)
    %(<direction><direction-type><words>Tempo</words></direction-type>#{offset && "<offset>#{offset}</offset>"}<sound tempo="#{bpm}"/></direction>)
  end

  describe "keys" do
    it "reads the opening key and mode" do
      flow = parse(musicxml_measures(whole_c, attributes: opening_attributes(fifths: -3, mode: "minor")))
      expect(flow.key_signature.name).to eq "C minor"
    end

    it "reads a signature with no mode as its major key" do
      expect(parse(musicxml_measures(whole_c, attributes: opening_attributes(fifths: 2))).key_signature.name).to eq "D major"
    end

    it "reads a mode" do
      expect(parse(musicxml_measures(whole_c, attributes: opening_attributes(fifths: 0, mode: "dorian"))).key_signature.name).to eq "D dorian"
    end

    it "reads a change at a later barline" do
      flow = parse(musicxml_measures(whole_c, key_attributes(1, "major") + whole_c))
      expect(flow.key_signature_change_at(2).name).to eq "G major"
    end

    it "reads back the writer's key and meter changes" do
      original = LilyPondFixtures.key_and_meter_change
      flow = round_trip(original)
      expect([flow.key_signature_changes.transform_values(&:to_s), flow.meter_changes.transform_values(&:to_s)])
        .to eq [original.key_signature_changes.transform_values(&:to_s), original.meter_changes.transform_values(&:to_s)]
    end

    it "adds no change where the key in force is stated again" do
      expect(parse(musicxml_measures(whole_c, key_attributes(0, "major") + whole_c)).key_signature_changes).to be_empty
    end

    it "skips a key in the middle of a bar" do
      flow = parse(musicxml_measures(whole_c, note_xml("C4", 2, "half") + key_attributes(2) + note_xml("D4", 2, "half")))
      expect(flow.key_signature_changes).to be_empty
    end

    it "keeps the first part's key where parts disagree" do
      flow = parse(musicxml_document([opening_attributes(fifths: 1) + whole_c], [opening_attributes(fifths: 3) + whole_c], attributes: nil))
      expect(flow.key_signature.name).to eq "G major"
    end
  end

  describe "meters" do
    it "reads a change at a later barline" do
      later = "<attributes><time><beats>3</beats><beat-type>4</beat-type></time></attributes>" + note_xml("D4", 3, "half", dots: 1)
      expect(parse(musicxml_measures(whole_c, later)).meter_changes.transform_values(&:to_s)).to eq(2 => "3/4")
    end

    it "skips a time in the middle of a bar" do
      middle = note_xml("C4", 2, "half") + "<attributes><time><beats>3</beats><beat-type>4</beat-type></time></attributes>" + note_xml("D4", 2, "half")
      expect(parse(musicxml_measures(whole_c, middle)).meter_changes).to be_empty
    end

    it "refuses a meter of added beats, naming the measure" do
      xml = musicxml_measures(note_xml("C4", 5, "half", dots: 1), attributes: opening_attributes(divisions: 2, beats: "3+2", beat_type: 8))
      expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::UnsupportedFeatureError, %r{3\+2/8.*\(measure 1 of part P1\)})
    end
  end

  describe "tempos" do
    it "reads an opening tempo" do
      expect(parse(musicxml_measures(tempo_direction(96) + whole_c)).tempo.beats_per_minute).to eq 96
    end

    it "reads a change at a later barline" do
      flow = parse(musicxml_measures(whole_c, tempo_direction(60) + whole_c))
      expect(flow.tempo_changes.transform_values(&:beats_per_minute)).to eq(2 => 60)
    end

    it "reads a tempo from any part" do
      flow = parse(musicxml_document([whole_c, whole_c], [whole_c, tempo_direction(72) + whole_c]))
      expect(flow.tempo_changes.transform_values(&:beats_per_minute)).to eq(2 => 72)
    end

    it "skips a tempo in the middle of a bar, and keeps the music whole" do
      flow = parse(musicxml_measures(whole_c, note_xml("D4", 2, "half") + tempo_direction(60) + note_xml("E4", 2, "half")))
      expect(flow.tempo_changes).to be_empty
      expect_music_whole(flow)
    end

    it "skips a tempo offset into the bar" do
      expect(parse(musicxml_measures(whole_c, tempo_direction(60, offset: 2) + whole_c)).tempo_changes).to be_empty
    end
  end
end
