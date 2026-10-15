require "spec_helper"

describe HeadMusic::Notation::MusicXML::TupletReader do
  def parse(xml)
    HeadMusic::Notation::MusicXML.parse(xml)
  end

  def triplet(pitch, tuplet: nil)
    note_xml(pitch, 1, "eighth", after: "<time-modification><actual-notes>3</actual-notes><normal-notes>2</normal-notes></time-modification>",
      notations: tuplet ? %(<tuplet type="#{tuplet}" number="1"/>) : "")
  end

  def tuplet_note(pitch, duration, type, (actual, normal), tuplet)
    note_xml(pitch, duration, type, after: "<time-modification><actual-notes>#{actual}</actual-notes><normal-notes>#{normal}</normal-notes></time-modification>",
      notations: tuplet ? %(<tuplet type="#{tuplet}" number="1"/>) : "")
  end

  let(:attributes) { opening_attributes(divisions: 3) }
  let(:rest_of_bar) { note_xml("G4", 9, "half", dots: 1) }

  describe "reading back the writer's tuplets" do
    (TupletFixtures.all - %i[grace_notes_before_downbeat grace_notes_in_pickup]).each do |fixture|
      context "with #{fixture}" do
        let(:original) { TupletFixtures.public_send(fixture) }
        let(:flow) { parse(HeadMusic::Notation::MusicXML.render(original)) }

        # A note the writer splits at a barline comes back as a chain of its
        # pieces, so each is compared by its exact onset and length.
        it "reads every voice event" do
          expect(sounding_summary(flow)).to eq sounding_summary(original)
        end

        it "brackets the same notes" do
          expect_same_tuplets(original, flow, bracketed: true)
        end

        it "keeps the music whole" do
          expect_music_whole(flow)
        end
      end
    end
  end

  it "groups a bracketed run with its unit" do
    flow = parse(musicxml_measures(triplet("C4", tuplet: "start") + triplet("D4") + triplet("E4", tuplet: "stop") + rest_of_bar, attributes: attributes))
    expect(tuplet_summary(flow)).to eq [[["1:1:000", "1:2:000", "triplet", "eighth"]]]
  end

  it "leaves a run with no <tuplet> ungrouped, keeping its ratio" do
    flow = parse(musicxml_measures(triplet("C4") + triplet("D4") + triplet("E4") + rest_of_bar, attributes: attributes))
    expect([flow.voices.first.tuplets, flow.voices.first.voice_events.first.rhythmic_value.to_s]).to eq [[], "triplet eighth"]
  end

  it "leaves a start with no stop ungrouped" do
    flow = parse(musicxml_measures(triplet("C4", tuplet: "start") + triplet("D4") + triplet("E4") + rest_of_bar, attributes: attributes))
    expect(flow.voices.first.tuplets).to be_empty
  end

  describe "a start with no stop before a later bracketed run" do
    let(:quarter_and_half) { note_xml("F4", 3, "quarter") + note_xml("G4", 6, "half") }
    let(:flow) do
      parse(musicxml_measures(
        triplet("C4", tuplet: "start") + triplet("D4") + triplet("E4") + quarter_and_half,
        triplet("C4", tuplet: "start") + triplet("D4") + triplet("E4", tuplet: "stop") + quarter_and_half,
        attributes: attributes
      ))
    end

    it "abandons the unstopped start, grouping only the later run" do
      expect(tuplet_summary(flow)).to eq [[["2:1:000", "2:2:000", "triplet", "eighth"]]]
    end

    it "keeps the abandoned run's ratio" do
      expect(flow.voices.first.voice_events.first.rhythmic_value.to_s).to eq "triplet eighth"
    end
  end

  it "abandons an unstopped start whose run another ratio ends" do
    triplets = [["C4", "start"], ["D4"], ["E4"]].map { |pitch, tuplet| tuplet_note(pitch, 20, "eighth", [3, 2], tuplet) }
    quintuplets = [["F4", "start"], ["G4"], ["A4"], ["B4"], ["C5", "stop"]].map { |pitch, tuplet| tuplet_note(pitch, 12, "16th", [5, 4], tuplet) }
    flow = parse(musicxml_measures((triplets + quintuplets).join + note_xml("D5", 120, "half"), attributes: opening_attributes(divisions: 60)))
    expect(tuplet_summary(flow)).to eq [[["1:2:000", "1:3:000", "5:4", "sixteenth"]]]
  end

  it "refuses a nested start whose ratio compounds the open run's, naming the measure" do
    measure = tuplet_note("F4", 12, "16th", [5, 4], "start") +
      tuplet_note("G4", 8, "16th", [15, 8], "start") + tuplet_note("A4", 8, "16th", [15, 8], nil) + tuplet_note("B4", 8, "16th", [15, 8], "stop") +
      tuplet_note("C5", 12, "16th", [5, 4], nil) + tuplet_note("D5", 12, "16th", [5, 4], "stop") + note_xml("E5", 180, "half", dots: 1)
    expect { parse(musicxml_measures(measure, attributes: opening_attributes(divisions: 60))) }
      .to raise_error(HeadMusic::Notation::MusicXML::UnsupportedFeatureError, /Nested tuplets.*\(measure 1 of part P1\)/)
  end

  it "skips a stop with no start" do
    flow = parse(musicxml_measures(triplet("C4") + triplet("D4") + triplet("E4", tuplet: "stop") + rest_of_bar, attributes: attributes))
    expect(flow.voices.first.tuplets).to be_empty
  end

  it "leaves ungrouped a bracket the voice refuses" do
    closing = note_xml("G4", 9, "half", dots: 1, notations: %(<tuplet type="stop" number="1"/>))
    flow = parse(musicxml_measures(triplet("C4") + triplet("D4") + triplet("E4", tuplet: "start") + closing, attributes: attributes))
    expect(flow.voices.first.tuplets).to be_empty
  end

  it "refuses nested tuplets, naming the measure" do
    xml = musicxml_measures(triplet("C4", tuplet: "start") + triplet("D4", tuplet: "start") + triplet("E4", tuplet: "stop") + rest_of_bar, attributes: attributes)
    expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::UnsupportedFeatureError, /Nested tuplets.*\(measure 1 of part P1\)/)
  end
end
