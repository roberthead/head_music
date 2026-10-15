require "spec_helper"

describe HeadMusic::Notation::MusicXML::TupletReader do
  def parse(xml)
    HeadMusic::Notation::MusicXML.parse(xml)
  end

  def triplet(pitch, tuplet: nil)
    note_xml(pitch, 1, "eighth", after: "<time-modification><actual-notes>3</actual-notes><normal-notes>2</normal-notes></time-modification>",
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
