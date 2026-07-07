require "spec_helper"

describe HeadMusic::Notation::MusicXML::Writer do
  def chain_length(rhythmic_value)
    1 + (rhythmic_value.tied_value ? chain_length(rhythmic_value.tied_value) : 0)
  end

  def pitched_note_count(composition)
    composition.voices.sum do |voice|
      voice.placements.select(&:note?).sum { |placement| chain_length(placement.rhythmic_value) }
    end
  end

  def note_element_texts(document, note_xpath)
    ["pitch/step", "pitch/octave", "duration", "type"].map do |element|
      xpath_text(document, "#{note_xpath}/#{element}")
    end
  end

  describe "#to_s" do
    context "with a single-voice diatonic tune" do
      let(:composition) { HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH) }
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "lists a single score part" do
        expect(xpath_count(document, "//part-list/score-part")).to eq 1
      end

      it "renders all eight bars as measures" do
        expect(xpath_count(document, "//part[@id='P1']/measure")).to eq 8
      end

      it "writes the divisions into the first measure" do
        expect(xpath_text(document, "//part/measure[1]/attributes/divisions")).to eq "2"
      end

      it "writes the key of G major as one sharp" do
        expect(xpath_text(document, "//part/measure[1]/attributes/key/fifths")).to eq "1"
      end

      it "writes the major mode" do
        expect(xpath_text(document, "//part/measure[1]/attributes/key/mode")).to eq "major"
      end

      it "writes the 4/4 time signature" do
        beats = xpath_text(document, "//part/measure[1]/attributes/time/beats")
        beat_type = xpath_text(document, "//part/measure[1]/attributes/time/beat-type")
        expect([beats, beat_type]).to eq %w[4 4]
      end

      it "selects a treble clef" do
        sign = xpath_text(document, "//part/measure[1]/attributes/clef/sign")
        line = xpath_text(document, "//part/measure[1]/attributes/clef/line")
        expect([sign, line]).to eq %w[G 2]
      end

      it "renders the opening note as an eighth-note G4" do
        expect(note_element_texts(document, "//part/measure[1]/note[1]")).to eq %w[G 4 1 eighth]
      end

      it "renders the third bar's opening note as a quarter-note C5" do
        expect(note_element_texts(document, "//part/measure[3]/note[1]")).to eq %w[C 5 2 quarter]
      end
    end

    context "with a small hand-built composition" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(
          name: "Exercise", key_signature: "G major", meter: "4/4", composer: "Aloysius"
        )
        voice = composition.add_voice
        voice.place("1:1", :quarter, "G4")
        voice.place("1:2", :quarter, "A4")
        voice.place("1:3", :quarter, "B4")
        voice.place("1:4", :quarter, "A4")
        voice.place("2:1", :half, "G4")
        voice.place("2:3", :half, "D5")
        composition
      end

      let(:expected) do
        <<~MUSICXML
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">
          <score-partwise version="4.0">
            <work>
              <work-title>Exercise</work-title>
            </work>
            <identification>
              <creator type="composer">Aloysius</creator>
              <encoding>
                <software>head_music #{HeadMusic::VERSION}</software>
              </encoding>
            </identification>
            <part-list>
              <score-part id="P1">
                <part-name>Voice 1</part-name>
              </score-part>
            </part-list>
            <part id="P1">
              <measure number="1">
                <attributes>
                  <divisions>1</divisions>
                  <key>
                    <fifths>1</fifths>
                    <mode>major</mode>
                  </key>
                  <time>
                    <beats>4</beats>
                    <beat-type>4</beat-type>
                  </time>
                  <clef>
                    <sign>G</sign>
                    <line>2</line>
                  </clef>
                </attributes>
                <note>
                  <pitch>
                    <step>G</step>
                    <octave>4</octave>
                  </pitch>
                  <duration>1</duration>
                  <type>quarter</type>
                </note>
                <note>
                  <pitch>
                    <step>A</step>
                    <octave>4</octave>
                  </pitch>
                  <duration>1</duration>
                  <type>quarter</type>
                </note>
                <note>
                  <pitch>
                    <step>B</step>
                    <octave>4</octave>
                  </pitch>
                  <duration>1</duration>
                  <type>quarter</type>
                </note>
                <note>
                  <pitch>
                    <step>A</step>
                    <octave>4</octave>
                  </pitch>
                  <duration>1</duration>
                  <type>quarter</type>
                </note>
              </measure>
              <measure number="2">
                <note>
                  <pitch>
                    <step>G</step>
                    <octave>4</octave>
                  </pitch>
                  <duration>2</duration>
                  <type>half</type>
                </note>
                <note>
                  <pitch>
                    <step>D</step>
                    <octave>5</octave>
                  </pitch>
                  <duration>2</duration>
                  <type>half</type>
                </note>
              </measure>
            </part>
          </score-partwise>
        MUSICXML
      end

      it "renders the exact golden document" do
        expect(described_class.new(composition).to_s).to eq expected
      end
    end

    context "with a chromatic tune" do
      let(:composition) { HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR) }
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "writes an alter element for the sharpened note in the first bar" do
        expect(xpath_texts(document, "//measure[@number='1']/note/pitch/alter")).to eq ["1"]
      end

      it "writes the flat and sharp alters of the second bar in order" do
        expect(xpath_texts(document, "//measure[@number='2']/note/pitch/alter")).to eq ["-1", "1"]
      end

      it "writes no alter element for a natural" do
        expect(xpath_text(document, "//measure[@number='1']/note[4]/pitch/step")).to eq "G"
        expect(xpath_count(document, "//measure[@number='1']/note[4]/pitch/alter")).to eq 0
      end
    end

    context "with rests" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(name: "Restful")
        voice = composition.add_voice
        voice.place("1:1", :quarter, "C4")
        voice.place("1:2", :quarter)
        voice.place("1:3", :half)
        voice.place("2:1", :whole, "D4")
        composition
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "renders a rest element instead of a pitch" do
        expect(xpath_count(document, "//measure[@number='1']/note[rest]")).to eq 2
      end

      it "renders the rest durations" do
        expect(xpath_texts(document, "//measure[@number='1']/note[rest]/duration")).to eq %w[1 2]
      end

      it "renders the rest types" do
        expect(xpath_texts(document, "//measure[@number='1']/note[rest]/type")).to eq %w[quarter half]
      end

      it "renders no tie or notations elements on rests" do
        expect(xpath_count(document, "//note[rest]/tie") + xpath_count(document, "//note[rest]/notations")).to eq 0
      end
    end

    context "with two voices of unequal lengths" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(name: "Duet")
        soprano = composition.add_voice(role: "Soprano")
        bass = composition.add_voice(role: "Bass")
        soprano.place("1:1", :whole, "E5")
        soprano.place("2:1", :whole, "D5")
        soprano.place("3:1", :whole, "C5")
        bass.place("1:1", :whole, "C3")
        composition
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "lists a score part per voice, named from the roles" do
        expect(xpath_texts(document, "//part-list/score-part/part-name")).to eq %w[Soprano Bass]
      end

      it "renders the same number of measures in both parts" do
        measure_counts = %w[P1 P2].map { |id| xpath_count(document, "//part[@id='#{id}']/measure") }
        expect(measure_counts).to eq [3, 3]
      end

      it "fills the shorter part's trailing measures with whole-measure rests" do
        rests = xpath_count(document, "//part[@id='P2']/measure[@number='2']/note/rest[@measure='yes']") +
          xpath_count(document, "//part[@id='P2']/measure[@number='3']/note/rest[@measure='yes']")
        expect(rests).to eq 2
      end

      it "gives the whole-measure rest a full bar's duration" do
        expect(xpath_text(document, "//part[@id='P2']/measure[@number='2']/note/duration")).to eq "4"
      end

      it "writes first-measure attributes into both parts" do
        expect(xpath_count(document, "//part/measure[1]/attributes/divisions")).to eq 2
      end

      it "selects a clef per voice" do
        signs = %w[P1 P2].map { |id| xpath_text(document, "//part[@id='#{id}']/measure[1]/attributes/clef/sign") }
        expect(signs).to eq %w[G F]
      end
    end

    context "with mid-piece meter and key signature changes given as strings" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(name: "Changes")
        voice = composition.add_voice
        %w[C4 D4 E4 F4].each_with_index { |pitch, index| voice.place("1:#{index + 1}", :quarter, pitch) }
        %w[G4 A4 B4 C5].each_with_index { |pitch, index| voice.place("2:#{index + 1}", :quarter, pitch) }
        voice.place("3:1", :eighth, "D5")
        voice.place("3:2", :eighth, "E5")
        voice.place("3:3", :eighth, "F#5")
        voice.place("4:1", :eighth, "D5")
        composition.change_meter(3, "3/8")
        composition.change_key_signature(3, "D major")
        composition
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "writes the changed key into the third measure" do
        fifths = xpath_text(document, "//measure[@number='3']/attributes/key/fifths")
        mode = xpath_text(document, "//measure[@number='3']/attributes/key/mode")
        expect([fifths, mode]).to eq %w[2 major]
      end

      it "writes the changed time signature into the third measure" do
        beats = xpath_text(document, "//measure[@number='3']/attributes/time/beats")
        beat_type = xpath_text(document, "//measure[@number='3']/attributes/time/beat-type")
        expect([beats, beat_type]).to eq %w[3 8]
      end

      it "writes only the changed elements" do
        unchanged = xpath_count(document, "//measure[@number='3']/attributes/divisions") +
          xpath_count(document, "//measure[@number='3']/attributes/clef")
        expect(unchanged).to eq 0
      end

      it "writes no attributes into the unchanged measures" do
        counts = %w[2 4].map { |number| xpath_count(document, "//measure[@number='#{number}']/attributes") }
        expect(counts).to eq [0, 0]
      end
    end

    context "with a tied chain" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(name: "Tied")
        voice = composition.add_voice
        value = HeadMusic::Rudiment::RhythmicValue.new(
          :half, tied_value: HeadMusic::Rudiment::RhythmicValue.get(:eighth)
        )
        voice.place("1:1", value, "C4")
        composition
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "renders one note per link of the chain" do
        expect(xpath_count(document, "//note")).to eq 2
      end

      it "renders the same pitch on both notes" do
        expect(xpath_texts(document, "//note/pitch/step")).to eq %w[C C]
      end

      it "renders the durations of the links" do
        expect(xpath_texts(document, "//note/duration")).to eq %w[4 1]
      end

      it "starts the tie on the first note only" do
        starts = [1, 2].map { |nth| xpath_count(document, "//note[#{nth}]/tie[@type='start']") }
        expect(starts).to eq [1, 0]
      end

      it "stops the tie on the second note only" do
        stops = [1, 2].map { |nth| xpath_count(document, "//note[#{nth}]/tie[@type='stop']") }
        expect(stops).to eq [0, 1]
      end

      it "renders the tied notation on both notes" do
        expect(xpath_count(document, "//note/notations/tied")).to eq 2
      end
    end

    context "with a pickup bar written out in full with leading rests" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(name: "Pickup Study")
        voice = composition.add_voice
        voice.place("0:1", :half)
        voice.place("0:3", :quarter)
        voice.place("0:4", :quarter, "G3")
        voice.place("1:1", :whole, "C4")
        composition
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "marks the pickup measure implicit" do
        expect(xpath_count(document, "//measure[@number='0'][@implicit='yes']")).to eq 1
      end

      it "leaves the following full measure explicit" do
        expect(xpath_count(document, "//measure[@number='1'][@implicit]")).to eq 0
      end

      it "renders the pickup bar's rests and note" do
        expect(xpath_count(document, "//measure[@number='0']/note/rest")).to eq 2
        expect(xpath_texts(document, "//measure[@number='0']/note/pitch/step")).to eq %w[G]
      end
    end

    context "with a rest carrying a tied chain" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(name: "Rest Chain")
        voice = composition.add_voice
        value = HeadMusic::Rudiment::RhythmicValue.new(
          :half, tied_value: HeadMusic::Rudiment::RhythmicValue.get(:eighth)
        )
        voice.place("1:1", value)
        composition
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "renders one independent rest per link of the chain" do
        expect(xpath_count(document, "//note/rest")).to eq 2
        expect(xpath_texts(document, "//note/duration")).to eq %w[4 1]
      end

      it "renders no tie elements or notations on the rests" do
        expect(xpath_count(document, "//note/tie")).to eq 0
        expect(xpath_count(document, "//note/notations")).to eq 0
      end
    end

    context "with a note that exactly fills more than one bar" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new
        voice = composition.add_voice
        voice.place("1:1", "double whole", "C4")
        composition
      end

      it "raises a render error naming the position" do
        expect { described_class.new(composition).to_s }.to raise_error(
          HeadMusic::Notation::MusicXML::RenderError,
          /the note at 1:1:000 crosses its barline/
        )
      end
    end

    context "with a composition that has no voices" do
      it "raises a render error" do
        composition = HeadMusic::Content::Composition.new
        expect { described_class.new(composition).to_s }
          .to raise_error(HeadMusic::Notation::MusicXML::RenderError, /no voices/)
      end
    end

    context "with a gap between placements" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new
        voice = composition.add_voice
        voice.place("1:1", :quarter, "C4")
        voice.place("1:3", :quarter, "D4")
        composition
      end

      it "raises a render error naming the expected and found positions" do
        expect { described_class.new(composition).to_s }.to raise_error(
          HeadMusic::Notation::MusicXML::RenderError,
          /expected a placement at 1:2:000, found one at 1:3:000/
        )
      end
    end

    context "with a first placement that starts mid-bar" do
      it "raises a render error" do
        composition = HeadMusic::Content::Composition.new
        voice = composition.add_voice
        voice.place("1:2", :quarter, "C4")
        expect { described_class.new(composition).to_s }
          .to raise_error(HeadMusic::Notation::MusicXML::RenderError, /first placement must start its bar/)
      end
    end

    context "with a note that crosses its barline" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new
        voice = composition.add_voice
        voice.place("1:1", :quarter, "C4")
        voice.place("1:2", :quarter, "D4")
        voice.place("1:3", :quarter, "E4")
        voice.place("1:4", :whole, "F4")
        composition
      end

      it "raises a render error naming the position" do
        expect { described_class.new(composition).to_s }.to raise_error(
          HeadMusic::Notation::MusicXML::RenderError,
          /the note at 1:4:000 crosses its barline/
        )
      end
    end

    context "with a control character in the composition name" do
      it "raises a render error" do
        composition = HeadMusic::Content::Composition.new(name: "Bad#{7.chr}Name")
        composition.add_voice
        expect { described_class.new(composition).to_s }
          .to raise_error(HeadMusic::Notation::MusicXML::RenderError, /control characters/)
      end
    end

    context "with markup characters in the free-text fields" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(name: 'Für <Elise> & "Friends"')
        voice = composition.add_voice(role: "Bob's part")
        voice.place("1:1", :whole, "C4")
        composition
      end
      let(:xml) { described_class.new(composition).to_s }

      it "escapes the work title" do
        expect(xml).to include "<work-title>Für &lt;Elise&gt; &amp; &quot;Friends&quot;</work-title>"
      end

      it "escapes the part name" do
        expect(xml).to include "<part-name>Bob&apos;s part</part-name>"
      end

      it "round-trips the title through an XML parse" do
        expect(xpath_text(parse_musicxml(xml), "//work-title")).to eq 'Für <Elise> & "Friends"'
      end
    end

    context "when rendering the shared ABC fixtures" do
      {
        "SPEED_THE_PLOUGH" => ABCFixtures::SPEED_THE_PLOUGH,
        "CHROMATIC_AIR" => ABCFixtures::CHROMATIC_AIR
      }.each do |fixture_name, abc|
        it "renders one pitched note per tied-chain link of #{fixture_name}" do
          composition = HeadMusic::Notation::ABC.parse(abc)
          document = parse_musicxml(described_class.new(composition).to_s)
          expect(xpath_count(document, "//note[pitch]")).to eq pitched_note_count(composition)
        end
      end
    end
  end
end
