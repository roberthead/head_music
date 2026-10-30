require "spec_helper"

describe HeadMusic::Notation::VoicePlacer do
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

  describe "notes and rests that do not print" do
    def hidden(xml)
      xml.sub("<note>", %(<note print-object="no">))
    end

    it "takes their time as a <forward> does, as a rest of the voice" do
      flow = parse(musicxml_measures(note_xml("C4", 1, "quarter") + hidden(note_xml("E4", 2, "half")) + note_xml("D4", 1, "quarter")))
      expect(voice_event_strings(flow).first).to eq ["quarter C4 at 1:1:000", "half rest at 1:2:000", "quarter D4 at 1:4:000"]
    end

    # music21 realizes a trill as a hidden voice, its first note fitting no
    # value; MuseScore hides rests beside a crossing hand in a voice 5.
    it "makes no voice of hidden notes and rests alone" do
      trill = [hidden(note_xml("G5", 230, voice: "2")), *Array.new(6) { hidden(note_xml("A5", 128, "32nd", voice: "2")) }].join
      first = note_xml("C4", 4096, "whole") + backup_xml(4096) + trill + forward_xml(3098, voice: "2")
      second = note_xml("D4", 4096, "whole") + backup_xml(4096) + hidden(measure_rest_xml(4096, voice: "5"))
      flow = parse(musicxml_measures(first, second, attributes: opening_attributes(divisions: 1024)))
      expect(voice_event_strings(flow)).to eq [["whole C4 at 1:1:000", "whole D4 at 2:1:000"]]
    end

    it "drops their chord tones, and a hidden chord tone of a printed note" do
      flow = parse(musicxml_measures(
        hidden(note_xml("C4", 2, "half")) + note_xml("E4", 2, "half", chord: true) + note_xml("D4", 2, "half") + hidden(note_xml("F4", 2, "half", chord: true))
      ))
      expect(voice_event_strings(flow).first).to eq ["half rest at 1:1:000", "half D4 at 1:3:000"]
    end

    it "drops a hidden grace note" do
      flow = parse(musicxml_measures(%(<note print-object="no"><grace/>#{pitch_xml("B3")}<type>eighth</type></note>) + note_xml("C4", 4, "whole")))
      expect(flow.voices.first.voice_events.first.grace_notes).to eq []
    end

    it "keeps the music whole" do
      expect_music_whole(parse(musicxml_measures(whole_c + backup_xml(4) + hidden(note_xml("E4", 2, "half", voice: "2")) + note_xml("F4", 2, "half", voice: "2"))))
    end
  end

  it "moves nothing for a <forward> or <backup> of no duration" do
    flow = parse(musicxml_measures(note_xml("C4", 2, "half") + forward_xml(0) + backup_xml(0) + note_xml("D4", 2, "half")))
    expect(voice_event_strings(flow).first).to eq ["half C4 at 1:1:000", "half D4 at 1:3:000"]
  end

  it "refuses a note of no duration" do
    expect { parse(musicxml_measures(note_xml("C4", 0, "half") + note_xml("D4", 4, "whole"))) }
      .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /A <duration> must be positive \(measure 1 of part P1\)/)
  end

  it "refuses a negative <forward>" do
    expect { parse(musicxml_measures(note_xml("C4", 4, "whole") + forward_xml(-1))) }
      .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /A <duration> must be positive/)
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

    it "raises on a <chord/> whose note before it is in another voice" do
      measure = note_xml("C4", 4, "whole", voice: "1") + backup_xml(4) + note_xml("E4", 4, "whole", voice: "2", chord: true)
      expect { parse(musicxml_measures(measure)) }
        .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /no note before it \(measure 1 of part P1\)/)
    end

    it "adds a <chord/> tone that names no voice to the note before it, as many exporters write one" do
      measure = note_xml("C4", 4, "whole", voice: "1") + backup_xml(4) + note_xml("G4", 4, "whole", voice: "2") + note_xml("B4", 4, "whole", chord: true)
      expect(parse(musicxml_measures(measure)).voices.map { |voice| voice.voice_events.first.pitches.map(&:to_s) }).to eq [%w[C4], %w[G4 B4]]
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

  describe "with trim_edges" do
    let(:reading) do
      Struct.new(:measures, :errors) { def where(index) = {measure: index} }
        .new(Array.new(4) { Struct.new(:implicit, :meter, :extent, :tolerance).new(false, HeadMusic::Rudiment::Meter.get("4/4"), nil, 0) }, HeadMusic::Notation::MusicXML)
    end

    def placed(*events)
      flow = HeadMusic::Content::Flow.new(meter: "4/4")
      voice = flow.add_voice
      track = HeadMusic::Notation::VoiceTrack.new("1")
      events.each do |index, cursor, value, fills|
        rhythmic_duration = value && HeadMusic::Rudiment::RhythmicDuration.get(value)
        track.add(measure_index: index, cursor: cursor, tolerance: Rational(1, 1000), rhythmic_duration: rhythmic_duration, duration: rhythmic_duration&.fraction || 0,
          sounds: value ? [HeadMusic::Rudiment::Pitch.get("C4")] : [], fills_bar: fills, tie_starts: [], tie_stops: [], staff: 1)
      end
      described_class.new(voice, track, HeadMusic::Notation::BarMap.new([reading]), reading, tuplet_reader: HeadMusic::Notation::MusicXML::TupletReader, trim_edges: true).place
      voice.voice_events.map(&:to_s)
    end

    it "places nothing for bars that whole-bar rests fill at the edges, and pads the last bar" do
      expect(placed([0, 0, nil, true], [1, 0, :half, false], [2, 0, nil, true], [3, 0, :quarter, false], [3, Rational(1, 4), nil, true]))
        .to eq ["half C4 at 2:1:000", "half rest at 2:3:000", "whole rest at 3:1:000", "quarter C4 at 4:1:000", "dotted half rest at 4:2:000"]
    end

    it "places nothing for a track of whole-bar rests alone" do
      expect(placed([0, 0, nil, true], [1, 0, nil, true])).to be_empty
    end
  end
end
