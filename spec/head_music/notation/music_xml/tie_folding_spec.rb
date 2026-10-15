require "spec_helper"

describe HeadMusic::Notation::MusicXML::TieFolding do
  def parse(xml)
    HeadMusic::Notation::MusicXML.parse(xml)
  end

  def tie(*types)
    types.map { |type| %(<tie type="#{type}"/>) }.join
  end

  def tied(*types)
    types.map { |type| %(<tied type="#{type}"/>) }.join
  end

  # Each voice event as [position, exact length, sounds], since a note the
  # writer splits at a barline comes back as a chain of its pieces.
  def lengths(flow)
    flow.voices.map do |voice|
      voice.voice_events.map { |event| [event.position.to_s, event.rhythmic_value.fraction, event.sounds.map(&:to_s)] }
    end
  end

  it "folds a tied pair into one voice event" do
    flow = parse(musicxml_measures(note_xml("C4", 2, "half", inside: tie("start")) + note_xml("C4", 2, "half", inside: tie("stop"))))
    expect(voice_event_strings(flow).first).to eq ["half tied to half C4 at 1:1:000"]
  end

  describe "a chain across barlines" do
    let(:flow) do
      parse(musicxml_measures(
        note_xml("C4", 2, "half") + note_xml("D4", 2, "half", inside: tie("start")),
        note_xml("D4", 4, "whole", inside: tie("stop", "start")),
        note_xml("D4", 2, "half", inside: tie("stop")) + note_xml("E4", 2, "half")
      ))
    end

    it "folds every link, keeping each one's written value" do
      expect(voice_event_strings(flow).first).to eq ["half C4 at 1:1:000", "half tied to whole tied to half D4 at 1:3:000", "half E4 at 3:3:000"]
    end

    it "keeps the music whole" do
      expect_music_whole(flow)
    end
  end

  it "folds a chord whose every pitch is tied" do
    flow = parse(musicxml_measures(
      note_xml("C4", 2, "half", inside: tie("start")) + note_xml("E4", 2, "half", chord: true, inside: tie("start")) +
      note_xml("C4", 2, "half", inside: tie("stop")) + note_xml("E4", 2, "half", chord: true, inside: tie("stop"))
    ))
    expect(voice_event_strings(flow).first).to eq ["half tied to half C4 E4 at 1:1:000"]
  end

  it "strikes again a chord whose pitches are only partly tied" do
    flow = parse(musicxml_measures(
      note_xml("C4", 2, "half", inside: tie("start")) + note_xml("E4", 2, "half", chord: true) +
      note_xml("C4", 2, "half", inside: tie("stop")) + note_xml("E4", 2, "half", chord: true)
    ))
    expect(voice_event_strings(flow).first).to eq ["half C4 E4 at 1:1:000", "half C4 E4 at 1:3:000"]
  end

  it "falls back to <tied> where there is no <tie>" do
    flow = parse(musicxml_measures(note_xml("C4", 2, "half", notations: tied("start")) + note_xml("C4", 2, "half", notations: tied("stop"))))
    expect(voice_event_strings(flow).first).to eq ["half tied to half C4 at 1:1:000"]
  end

  it "lets <tie> win where it disagrees with <tied>" do
    flow = parse(musicxml_measures(
      note_xml("C4", 2, "half", inside: tie("start"), notations: tied("let-ring")) + note_xml("C4", 2, "half", inside: tie("stop"))
    ))
    expect(voice_event_strings(flow).first).to eq ["half tied to half C4 at 1:1:000"]
  end

  it "skips let-ring and continue" do
    flow = parse(musicxml_measures(note_xml("C4", 2, "half", notations: tied("let-ring")) + note_xml("C4", 2, "half", notations: tied("continue"))))
    expect(voice_event_strings(flow).first).to eq ["half C4 at 1:1:000", "half C4 at 1:3:000"]
  end

  describe "a tie with no stop" do
    let(:flow) { parse(musicxml_measures(note_xml("C4", 2, "half") + note_xml("D4", 2, "half", inside: tie("start")))) }

    it "is dropped, its note keeping its written value" do
      expect(voice_event_strings(flow).first).to eq ["half C4 at 1:1:000", "half D4 at 1:3:000"]
    end

    it "keeps the music whole" do
      expect_music_whole(flow)
    end
  end

  it "drops a tie followed by a rest" do
    flow = parse(musicxml_measures(note_xml("D4", 2, "half", inside: tie("start")) + rest_xml(1, "quarter") + note_xml("D4", 1, "quarter", inside: tie("stop"))))
    expect(voice_event_strings(flow).first).to eq ["half D4 at 1:1:000", "quarter rest at 1:3:000", "quarter D4 at 1:4:000"]
  end

  it "raises on a tie between different pitches, naming the measure it starts in" do
    xml = musicxml_measures([note_xml("C4", 4, "whole", inside: tie("start")), {number: "5"}], [note_xml("D4", 4, "whole", inside: tie("stop")), {number: "6"}])
    expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::ParseError, /tie connects C4 to D4 \(measure 5 of part P1\)/)
  end

  describe "ties between chords that share only some pitches" do
    it "strikes a chord again when only one of its tied pitches goes on" do
      flow = parse(musicxml_measures(
        note_xml("G3", 2, "half", inside: tie("start")) + note_xml("D4", 2, "half", chord: true, inside: tie("start")) +
          note_xml("G3", 2, "half", inside: tie("stop"))
      ))
      expect(voice_event_strings(flow).first).to eq ["half G3 D4 at 1:1:000", "half G3 at 1:3:000"]
    end

    it "strikes a note again that a chord takes up with another pitch" do
      flow = parse(musicxml_measures(
        note_xml("Ab4", 2, "half", inside: tie("start")) + note_xml("Ab4", 2, "half", inside: tie("stop")) +
          note_xml("Bb3", 2, "half", chord: true, inside: tie("stop"))
      ))
      expect(voice_event_strings(flow).first).to eq ["half A♭4 at 1:1:000", "half A♭4 B♭3 at 1:3:000"]
    end
  end

  describe "reading back the writer's ties" do
    %i[fourth_species tie_into_key_change tie_into_meter_change].each do |fixture|
      it "keeps every note of #{fixture} as long as it was" do
        original = LilyPondFixtures.public_send(fixture)
        expect(lengths(parse(HeadMusic::Notation::MusicXML.render(original)))).to eq lengths(original)
      end
    end
  end
end
