require "spec_helper"

describe HeadMusic::Notation::MusicXML::WrittenTiming do
  def parse(xml)
    HeadMusic::Notation::MusicXML.parse(xml)
  end

  def document(*measures)
    musicxml_measures(*measures, attributes: opening_attributes(divisions: 10))
  end

  def triplet(pitch, duration, voice: nil)
    note_xml(pitch, duration, "eighth", voice: voice, after: "<time-modification><actual-notes>3</actual-notes><normal-notes>2</normal-notes></time-modification>")
  end

  # Triplet eighths at 10 divisions, each <duration> rounded to 4 or 3, so
  # every beat's three take 11 divisions.
  def drifting_triplets(*pitches, voice: nil)
    pitches.each_with_index.map { |pitch, index| triplet(pitch, (index % 3 == 1) ? 3 : 4, voice: voice) }.join
  end

  let(:twelve) { %w[C4 D4 E4] * 4 }
  let(:whole_d) { note_xml("D4", 40, "whole") }

  describe "a measure of triplet eighths whose durations drift past the bar" do
    let(:flow) { parse(document(drifting_triplets(*twelve), whole_d)) }

    it "times the measure by its written values" do
      expect(voice_event_strings(flow).first.values_at(0, 1, 2, 3, 11, 12)).to eq [
        "triplet eighth C4 at 1:1:000", "triplet eighth D4 at 1:1:320", "triplet eighth E4 at 1:1:640",
        "triplet eighth C4 at 1:2:000", "triplet eighth E4 at 1:4:640", "whole D4 at 2:1:000"
      ]
    end

    it "keeps the music whole" do
      expect_music_whole(flow)
    end
  end

  it "places a direction where the written values reach" do
    measure = drifting_triplets(*twelve.first(11)) + "<direction><direction-type><dynamics><f/></dynamics></direction-type></direction>" +
      triplet("E4", 4)
    expect(parse(document(measure, whole_d)).parts.first.dynamic_events.map { |event| event.position.to_s }).to eq ["1:4:640"]
  end

  describe "a measure whose <backup> drifts" do
    let(:flow) do
      parse(document(
        note_xml("E3", 20, "half", voice: "2") + backup_xml(20) +
          note_xml("C5", 20, "half", voice: "1") + drifting_triplets(*%w[C4 D4 E4 C4 D4 E4], voice: "1") +
          backup_xml(22) + note_xml("G3", 20, "half", voice: "2"),
        whole_d
      ))
    end

    it "lands the backup on the nearest written onset" do
      expect(voice_event_strings(flow)).to include ["half E3 at 1:1:000", "half G3 at 1:3:000", "whole rest at 2:1:000"]
    end

    it "keeps the music whole" do
      expect_music_whole(flow)
    end
  end

  it "reads a rest with no <type> over the bar by a division as a whole-measure rest" do
    flow = parse(document(rest_xml(41), whole_d))
    expect(voice_event_strings(flow).first).to eq ["whole rest at 1:1:000", "whole D4 at 2:1:000"]
  end

  # These raised before written values were trusted, and must still.
  describe "a drifting measure whose written values do not fill the bar" do
    it "still refuses a voice with a note too many" do
      xml = document(drifting_triplets(*twelve) + note_xml("F4", 5, "eighth"), whole_d)
      expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::UnsupportedFeatureError, /longer than its 4\/4 bar \(measure 1 of part P1\)/)
    end

    it "still refuses it when another voice falls short" do
      xml = document(drifting_triplets(*twelve, voice: "1") + backup_xml(44) + note_xml("G3", 20, "half", voice: "2"), whole_d)
      expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::UnsupportedFeatureError, /longer than its 4\/4 bar \(measure 1 of part P1\)/)
    end

    it "still refuses a note with no <type>" do
      xml = document(drifting_triplets(*twelve.first(11)) + note_xml("E4", 4), whole_d)
      expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::UnsupportedFeatureError, /longer than its 4\/4 bar \(measure 1 of part P1\)/)
    end
  end
end
