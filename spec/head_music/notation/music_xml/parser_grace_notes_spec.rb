require "spec_helper"

describe HeadMusic::Notation::MusicXML::Parser do
  def parse(xml)
    described_class.new(xml).flow
  end

  def grace_xml(pitch, type = "eighth", slash: false, chord: false, inside: "", notations: "")
    grace = slash ? %(<grace slash="yes"/>) : "<grace/>"
    note_xml(pitch, nil, type, chord: chord, inside: inside, notations: notations).sub("<note>", "<note>#{grace}")
  end

  def graces(flow)
    flow.voices.first.note_events.reject { |event| event.grace_notes.empty? }.map do |event|
      [event.position.to_s, event.grace_notes.map(&:to_s)]
    end
  end

  let(:main) { note_xml("C5", 4, "whole") }

  describe "reading back the writer's grace notes" do
    %i[grace_notes_before_downbeat grace_notes_in_pickup].each do |fixture|
      context "with #{fixture}" do
        let(:original) { TupletFixtures.public_send(fixture) }
        let(:flow) { parse(HeadMusic::Notation::MusicXML.render(original)) }

        it "reads every grace note" do
          expect(grace_summary(flow).map(&:first)).to eq grace_summary(original).map(&:first)
        end

        it "reads every voice event" do
          expect(voice_event_strings(flow)).to eq voice_event_strings(original)
        end

        it "keeps the music whole" do
          expect_music_whole(flow)
        end
      end
    end
  end

  it "gives a grace note to the next main note of its voice" do
    expect(graces(parse(musicxml_measures(grace_xml("D5", slash: true) + main)))).to eq [["1:1:000", ["slashed grace eighth D5"]]]
  end

  it "reads a grace chord as one grace note with several pitches" do
    flow = parse(musicxml_measures(grace_xml("D5", "16th") + grace_xml("F5", "16th", chord: true) + main))
    expect(graces(flow)).to eq [["1:1:000", ["grace sixteenth D5 F5"]]]
  end

  it "reads a grace note with no type as an eighth" do
    expect(graces(parse(musicxml_measures(grace_xml("D5", nil) + main)))).to eq [["1:1:000", ["grace eighth D5"]]]
  end

  it "keeps a grace note's articulations" do
    flow = parse(musicxml_measures(grace_xml("D5", notations: "<articulations><staccato/></articulations>") + main))
    expect(flow.voices.first.voice_events.first.grace_notes.first.articulations.map(&:name_key)).to eq ["staccato"]
  end

  it "drops grace notes before a rest" do
    expect(graces(parse(musicxml_measures(grace_xml("D5") + rest_xml(4, "whole"))))).to be_empty
  end

  it "drops grace notes before a tie's later link" do
    flow = parse(musicxml_measures(
      note_xml("C5", 2, "half", inside: %(<tie type="start"/>)) + grace_xml("D5") + note_xml("C5", 2, "half", inside: %(<tie type="stop"/>))
    ))
    expect([graces(flow), voice_event_strings(flow).first]).to eq [[], ["half tied to half C5 at 1:1:000"]]
  end

  it "drops grace notes at the end of the part" do
    expect(graces(parse(musicxml_measures(main + grace_xml("D5"))))).to be_empty
  end

  describe "a grace note tied into its main note" do
    let(:flow) do
      parse(musicxml_measures(
        note_xml("C5", 2, "half", inside: %(<tie type="start"/>)) +
          grace_xml("C5", inside: %(<tie type="start"/>)) + note_xml("C5", 2, "half", inside: %(<tie type="stop"/>))
      ))
    end

    it "is tied" do
      expect(flow.voices.first.voice_events.last.grace_notes.first).to be_tied
    end

    it "takes the place of the main note's stop, so no chain ends there" do
      expect(voice_event_strings(flow).first).to eq ["half C5 at 1:1:000", "half C5 at 1:3:000"]
    end
  end
end
