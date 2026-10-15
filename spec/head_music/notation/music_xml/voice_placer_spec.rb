require "spec_helper"

describe HeadMusic::Notation::MusicXML::VoicePlacer do
  def parse(xml)
    HeadMusic::Notation::MusicXML.parse(xml)
  end

  let(:whole_c) { note_xml("C4", 4, "whole") }

  describe "voices in one part" do
    let(:flow) do
      parse(musicxml_measures(
        note_xml("E5", 4, "whole", voice: "upper") + backup_xml(4) + note_xml("C4", 2, "half", voice: "lower") + note_xml("D4", 2, "half", voice: "lower"),
        note_xml("F5", 4, "whole", voice: "upper") + backup_xml(4) + note_xml("B3", 4, "whole", voice: "lower")
      ))
    end

    it "makes a voice of each <voice> value, in order of first appearance" do
      expect(voice_event_strings(flow)).to eq [
        ["whole E5 at 1:1:000", "whole F5 at 2:1:000"],
        ["half C4 at 1:1:000", "half D4 at 1:3:000", "whole B3 at 2:1:000"]
      ]
    end

    it "keeps them in one part" do
      expect(flow.parts.map { |part| part.voices.length }).to eq [2]
    end

    it "keeps the music whole" do
      expect_music_whole(flow)
    end
  end

  it "reads a note with no <voice> as voice 1" do
    flow = parse(musicxml_measures(note_xml("E5", 4, "whole", voice: "2") + backup_xml(4) + note_xml("C4", 4, "whole")))
    expect(voice_event_strings(flow)).to eq [["whole E5 at 1:1:000"], ["whole C4 at 1:1:000"]]
  end

  it "fills a <forward> gap with a rest" do
    flow = parse(musicxml_measures(note_xml("C4", 1, "quarter") + forward_xml(2) + note_xml("D4", 1, "quarter")))
    expect(voice_event_strings(flow).first).to eq ["quarter C4 at 1:1:000", "half rest at 1:2:000", "quarter D4 at 1:4:000"]
  end

  describe "a voice that begins late and ends early" do
    let(:flow) do
      parse(musicxml_measures(
        whole_c,
        whole_c + backup_xml(2) + note_xml("G4", 2, "half", voice: "2"),
        whole_c
      ))
    end

    it "pads it with rests split at the barlines" do
      expect(voice_event_strings(flow).last).to eq ["whole rest at 1:1:000", "half rest at 2:1:000", "half G4 at 2:3:000", "whole rest at 3:1:000"]
    end

    it "keeps the music whole" do
      expect_music_whole(flow)
    end
  end

  describe "a part with fewer measures than the first" do
    let(:flow) { parse(musicxml_document([whole_c, whole_c, whole_c], [note_xml("C3", 4, "whole")])) }

    it "pads it with rests" do
      expect(voice_event_strings(flow).last).to eq ["whole C3 at 1:1:000", "whole rest at 2:1:000", "whole rest at 3:1:000"]
    end

    it "keeps the music whole" do
      expect_music_whole(flow)
    end
  end

  it "raises on a <backup> before the start of its measure, naming it" do
    xml = musicxml_measures(whole_c, [note_xml("D4", 2, "half") + backup_xml(3), {number: "2"}])
    expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::ParseError, /<backup>.*\(measure 2 of part P1\)/)
  end

  it "raises on a voice that overlaps itself" do
    xml = musicxml_measures(note_xml("C4", 2, "half") + backup_xml(1) + note_xml("D4", 2, "half"), note_xml("E4", 4, "whole"))
    expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::ParseError, /Voice 1 overlaps itself \(measure 1 of part P1\)/)
  end

  describe "chords" do
    it "adds a <chord/> tone to the note before it" do
      flow = parse(musicxml_measures(note_xml("C4", 4, "whole") + note_xml("E4", 4, "whole", chord: true) + note_xml("G4", 4, "whole", chord: true)))
      expect(flow.voices.first.voice_events.first.pitches.map(&:to_s)).to eq %w[C4 E4 G4]
    end

    it "raises on a <chord/> with no note before it" do
      expect { parse(musicxml_measures(note_xml("E4", 4, "whole", chord: true))) }
        .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /no note before it \(measure 1 of part P1\)/)
    end

    it "raises on a <chord/> after a rest" do
      expect { parse(musicxml_measures(rest_xml(4, "whole") + note_xml("E4", 4, "whole", chord: true))) }
        .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /no note before it/)
    end

    it "refuses chord tones of different lengths" do
      expect { parse(musicxml_measures(note_xml("C4", 2, "half") + note_xml("E4", 1, "quarter", chord: true) + note_xml("D4", 2, "half"))) }
        .to raise_error(HeadMusic::Notation::MusicXML::UnsupportedFeatureError, /different lengths are not supported \(measure 1 of part P1\)/)
    end
  end

  describe "cue notes" do
    let(:flow) do
      parse(musicxml_measures(note_xml("C4", 2, "half") + note_xml("D5", 2, "half", inside: "<cue/>") + note_xml("F5", 2, "half", chord: true, inside: "<cue/>")))
    end

    it "reads them as rests of their length, dropping their chord tones" do
      expect(voice_event_strings(flow).first).to eq ["half C4 at 1:1:000", "half rest at 1:3:000"]
    end

    it "keeps the music whole" do
      expect_music_whole(flow)
    end
  end

  describe "unpitched notes" do
    let(:unpitched) { "<note><unpitched><display-step>C</display-step><display-octave>5</display-octave></unpitched><duration>4</duration><type>whole</type></note>" }

    it "sound the part's instrument" do
      part_list = %(<part-list><score-part id="P1"><part-name>Snare</part-name><score-instrument id="P1-I1"><instrument-name>Snare</instrument-name>) +
        %(<instrument-sound>drum.snare-drum</instrument-sound></score-instrument></score-part></part-list>)
      flow = parse(musicxml_measures(unpitched).sub(%r{<part-list>.*</part-list>}m, part_list))
      expect(flow.voices.first.voice_events.first.sounds.first.name_key).to eq :snare_drum
    end

    it "are an unpitched sound of no instrument where the part has none" do
      expect(parse(musicxml_measures(unpitched)).voices.first.voice_events.first.sounds).to eq [HeadMusic::Rudiment::UnpitchedSound.get(nil)]
    end
  end

  it "skips a <multiple-rest>" do
    style = "<attributes><measure-style><multiple-rest>2</multiple-rest></measure-style></attributes>"
    flow = parse(musicxml_measures(whole_c, style + measure_rest_xml(4), measure_rest_xml(4), whole_c))
    expect(voice_event_strings(flow).first).to eq ["whole C4 at 1:1:000", "whole rest at 2:1:000", "whole rest at 3:1:000", "whole C4 at 4:1:000"]
  end

  it "refuses a <measure-repeat>, naming the measure" do
    style = "<attributes><measure-style><measure-repeat type=\"start\">1</measure-repeat></measure-style></attributes>"
    xml = musicxml_measures(whole_c, [style + measure_rest_xml(4), {number: "2"}])
    expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::UnsupportedFeatureError, /measure-repeat.*\(measure 2 of part P1\)/)
  end

  describe "reading back the writer's voices" do
    let(:original) do
      HeadMusic::Content::Flow.new(name: "Duet", key_signature: "C major", meter: "4/4").tap do |duet|
        part = duet.add_part
        upper = part.add_voice
        lower = part.add_voice
        upper.place("1:1", :half, "E5")
        upper.place("1:3", :half, %w[F5 A5])
        upper.place("2:1", :whole, "G5")
        lower.place("1:1", :whole, "C4")
        lower.place("2:1", :half)
        lower.place("2:3", :half, "B3")
      end
    end

    it "reads every voice event the writer wrote" do
      expect(voice_event_strings(HeadMusic::Notation::MusicXML.parse(HeadMusic::Notation::MusicXML.render(original)))).to eq voice_event_strings(original)
    end
  end
end
