require "spec_helper"

describe HeadMusic::Notation::MusicXML::Writer do
  def chain_length(rhythmic_value)
    1 + (rhythmic_value.tied_value ? chain_length(rhythmic_value.tied_value) : 0)
  end

  def pitched_note_count(composition)
    composition.voices.sum do |voice|
      voice.placements.select(&:sounded?).sum { |placement| chain_length(placement.rhythmic_value) }
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

    context "with lyrics" do
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      context "with a single-verse single word" do
        let(:composition) do
          composition = HeadMusic::Content::Composition.new(name: "Sung")
          composition.add_voice.place("1:1", :whole, "C4").sing("la")
          composition
        end

        it "renders the syllable text" do
          expect(xpath_text(document, "//measure[@number='1']/note/lyric/text")).to eq "la"
        end

        it "marks a whole word as single" do
          expect(xpath_text(document, "//measure[@number='1']/note/lyric/syllabic")).to eq "single"
        end

        it "numbers the verse" do
          expect(xpath_count(document, "//measure[@number='1']/note/lyric[@number='1']")).to eq 1
        end
      end

      context "with a hyphenated word across three notes" do
        let(:composition) do
          composition = HeadMusic::Content::Composition.new(name: "Kyrie")
          voice = composition.add_voice
          voice.place("1:1", :quarter, "C4").sing("Ky", hyphen_after: true)
          voice.place("1:2", :quarter, "D4").sing("ri", hyphen_after: true)
          voice.place("1:3", :half, "E4").sing("e")
          composition
        end

        it "derives begin, middle, and end from the hyphen booleans" do
          expect(xpath_texts(document, "//measure[@number='1']/note/lyric/syllabic")).to eq %w[begin middle end]
        end
      end

      context "with a melisma (a syllable held over several notes)" do
        let(:composition) do
          composition = HeadMusic::Content::Composition.new(name: "Amen")
          voice = composition.add_voice
          voice.place("1:1", :half, "C4").sing("A")
          voice.place("1:3", :half, "D4") # held: no syllable
          composition
        end

        it "emits a lyric only on the attacked syllable" do
          expect(xpath_count(document, "//measure[@number='1']/note/lyric")).to eq 1
        end
      end

      context "with a hyphenated word straddling a melisma gap" do
        let(:composition) do
          composition = HeadMusic::Content::Composition.new(name: "Gapped")
          voice = composition.add_voice
          voice.place("1:1", :quarter, "C4").sing("Ky", hyphen_after: true)
          voice.place("1:2", :quarter, "D4") # held: no syllable
          voice.place("1:3", :quarter, "E4").sing("ri", hyphen_after: true)
          voice.place("1:4", :quarter, "F4").sing("e")
          composition
        end

        it "derives syllabic from the previous sung note, skipping the gap" do
          expect(xpath_texts(document, "//measure[@number='1']/note/lyric/syllabic")).to eq %w[begin middle end]
        end
      end

      context "with verses whose hyphenation differs" do
        let(:composition) do
          composition = HeadMusic::Content::Composition.new(name: "Independent")
          voice = composition.add_voice
          voice.place("1:1", :quarter, "C4").sing("A", hyphen_after: true).sing("go", verse: 2)
          voice.place("1:2", :quarter, "D4").sing("men").sing("now", verse: 2)
          composition
        end

        it "derives each verse's syllabic independently" do
          cells = [[1, 1], [1, 2], [2, 1], [2, 2]]
          syllabics = cells.map do |note, verse|
            xpath_text(document, "//measure[@number='1']/note[#{note}]/lyric[@number='#{verse}']/syllabic")
          end
          expect(syllabics).to eq %w[begin single end single]
        end
      end

      context "with multiple verses on one note" do
        let(:composition) do
          composition = HeadMusic::Content::Composition.new(name: "Verses")
          composition.add_voice.place("1:1", :whole, "C4").sing("glo").sing("peace", verse: 2)
          composition
        end

        it "renders one lyric per verse, numbered" do
          numbers = %w[1 2].map { |n| xpath_count(document, "//measure[@number='1']/note/lyric[@number='#{n}']") }
          expect(numbers).to eq [1, 1]
        end

        it "renders each verse's text in order" do
          expect(xpath_texts(document, "//measure[@number='1']/note/lyric/text")).to eq %w[glo peace]
        end
      end

      context "with a chord" do
        let(:composition) do
          composition = HeadMusic::Content::Composition.new(name: "Chorale")
          composition.add_voice.place("1:1", :whole, %w[C4 E4 G4]).sing("chord")
          composition
        end

        it "renders the lyric only on the lead note of the chord" do
          expect(xpath_count(document, "//measure[@number='1']/note/lyric")).to eq 1
        end
      end

      context "with a tied note" do
        let(:composition) do
          composition = HeadMusic::Content::Composition.new(name: "Tied")
          composition.add_voice.place("1:1", "half tied to eighth", "C4").sing("held")
          composition
        end

        it "renders the lyric only on the attack of the tied chain" do
          expect(xpath_count(document, "//measure[@number='1']/note/lyric")).to eq 1
        end
      end

      context "with markup characters in the text" do
        let(:composition) do
          composition = HeadMusic::Content::Composition.new(name: "Escaped")
          composition.add_voice.place("1:1", :whole, "C4").sing("R&D <x>")
          composition
        end

        it "escapes the text so the document stays well-formed" do
          expect(xpath_text(document, "//measure[@number='1']/note/lyric/text")).to eq "R&D <x>"
        end
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

    context "with a tie authored in ABC input" do
      let(:composition) do
        HeadMusic::Notation::ABC.parse("X:1\nT:Tie\nM:6/8\nL:1/8\nK:C\nE3-E2 G |]\n")
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "renders the authored split as a dotted quarter, a quarter, and the following eighth" do
        expect(xpath_texts(document, "//note/type")).to eq %w[quarter quarter eighth]
        expect(xpath_count(document, "//note[1]/dot")).to eq 1
      end

      it "ties the first two notes together and leaves the third free" do
        starts = (1..3).map { |nth| xpath_count(document, "//note[#{nth}]/notations/tied[@type='start']") }
        stops = (1..3).map { |nth| xpath_count(document, "//note[#{nth}]/notations/tied[@type='stop']") }
        expect(starts).to eq [1, 0, 0]
        expect(stops).to eq [0, 1, 0]
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

    context "with a chord placement" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new
        voice = composition.add_voice
        voice.place("1:1", :half, %w[C4 E4 G4])
        composition
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "emits one note per pitched sound" do
        expect(xpath_count(document, "//measure[1]/note")).to eq 3
      end

      it "marks every note but the lowest with a chord element" do
        expect(xpath_count(document, "//measure[1]/note/chord")).to eq 2
      end

      it "leaves the lowest note free of a chord element" do
        expect(xpath_count(document, "//measure[1]/note[1]/chord")).to eq 0
      end

      it "renders the notes low to high" do
        expect(xpath_texts(document, "//measure[1]/note/pitch/step")).to eq %w[C E G]
      end

      it "shares the placement's duration across every note" do
        expect(xpath_texts(document, "//measure[1]/note/duration")).to eq %w[2 2 2]
      end
    end

    context "with a chord, checking exact note markup" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new
        voice = composition.add_voice
        voice.place("1:1", :half, %w[C4 E4])
        composition
      end

      # <chord/> must be the note's first child, before <pitch>; count-based
      # XPath assertions cannot see child order, so this pins it by string.
      let(:expected_notes) do
        <<~NOTES.chomp
          <note>
                  <pitch>
                    <step>C</step>
                    <octave>4</octave>
                  </pitch>
                  <duration>2</duration>
                  <type>half</type>
                </note>
                <note>
                  <chord/>
                  <pitch>
                    <step>E</step>
                    <octave>4</octave>
                  </pitch>
                  <duration>2</duration>
                  <type>half</type>
                </note>
        NOTES
      end

      it "places the chord element before the pitch on the upper note" do
        expect(described_class.new(composition).to_s).to include(expected_notes)
      end
    end

    context "with a chord whose sounds are placed high to low" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new
        voice = composition.add_voice
        voice.place("1:1", :half, %w[G4 C4 E4])
        composition
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "still emits the notes low to high" do
        expect(xpath_texts(document, "//measure[1]/note/pitch/step")).to eq %w[C E G]
      end
    end

    context "with a two-pitch chord placement" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new
        voice = composition.add_voice
        voice.place("1:1", :half, %w[C4 E4])
        composition
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "emits two notes, the upper one carrying a chord element" do
        expect(xpath_count(document, "//measure[1]/note")).to eq 2
        expect(xpath_count(document, "//measure[1]/note/chord")).to eq 1
      end
    end

    context "with a measure mixing a chord and a single note" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(meter: "4/4")
        voice = composition.add_voice
        voice.place("1:1", :half, %w[C4 E4 G4])
        voice.place("1:3", :half, "D5")
        composition
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "emits the chord's stacked notes followed by the single note" do
        expect(xpath_texts(document, "//measure[1]/note/pitch/step")).to eq %w[C E G D]
      end

      it "marks only the chord's upper notes with a chord element" do
        expect(xpath_count(document, "//measure[1]/note/chord")).to eq 2
      end

      it "gives every note a half-note duration" do
        expect(xpath_texts(document, "//measure[1]/note/duration")).to eq %w[2 2 2 2]
      end
    end

    context "with a tied chord" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(meter: "4/4")
        voice = composition.add_voice
        value = HeadMusic::Rudiment::RhythmicValue.new(
          :half, tied_value: HeadMusic::Rudiment::RhythmicValue.get(:eighth)
        )
        voice.place("1:1", value, %w[C4 E4 G4])
        composition
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "renders a full chord stack for each tied link" do
        expect(xpath_count(document, "//measure[1]/note")).to eq 6
        expect(xpath_count(document, "//measure[1]/note/chord")).to eq 4
      end

      it "ties every note of the sustained chord" do
        expect(xpath_count(document, "//measure[1]/note/tie[@type='start']")).to eq 3
        expect(xpath_count(document, "//measure[1]/note/tie[@type='stop']")).to eq 3
      end
    end

    context "with a single unpitched sound placement" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new
        voice = composition.add_voice
        voice.place("1:1", :quarter, HeadMusic::Rudiment::UnpitchedSound.get("snare drum"))
        composition
      end

      it "raises a render error naming the sound and position" do
        expect { described_class.new(composition).to_s }.to raise_error(
          HeadMusic::Notation::MusicXML::RenderError,
          /cannot render unpitched sound "snare drum" at 1:1.*percussion rendering is not yet supported/
        )
      end
    end

    context "with a mixed pitched and unpitched placement" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new
        voice = composition.add_voice
        voice.place("1:1", :quarter, ["C4", HeadMusic::Rudiment::UnpitchedSound.get("snare drum")])
        composition
      end

      it "raises a render error naming the unpitched sound" do
        expect { described_class.new(composition).to_s }.to raise_error(
          HeadMusic::Notation::MusicXML::RenderError,
          /cannot render unpitched sound "snare drum" at 1:1/
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

    # Default (meter-derived) beaming applies when placements carry no authored
    # beam flag, so these build the composition programmatically — ABC input is
    # authoritative (every adjacency implies a join) and cannot express "no
    # opinion" for interior notes.
    context "with eight default-beamed eighth notes in 4/4" do
      let(:composition) do
        HeadMusic::Content::Composition.new(meter: "4/4").tap do |composition|
          voice = composition.add_voice
          8.times { voice.place(voice.next_position, :eighth, "C4") }
        end
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "beams four two-note groups, one per beat" do
        expect(xpath_texts(document, "//measure[@number='1']/note/beam[@number='1']"))
          .to eq %w[begin end begin end begin end begin end]
      end

      it "breaks every group at the beat, never continuing across one" do
        expect(xpath_count(document, "//measure[@number='1']/note/beam[.='continue']")).to eq 0
      end
    end

    context "with six default-beamed eighth notes in 6/8" do
      let(:composition) do
        HeadMusic::Content::Composition.new(meter: "6/8").tap do |composition|
          voice = composition.add_voice
          6.times { voice.place(voice.next_position, :eighth, "C4") }
        end
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "beams two three-note groups on the dotted-quarter boundary" do
        expect(xpath_texts(document, "//measure[@number='1']/note/beam[@number='1']"))
          .to eq %w[begin continue end begin continue end]
      end
    end

    # Authored ABC spacing is honored verbatim: adjacent notes beam together
    # even across a beat, and a space breaks the beam (the confirmed override).
    context "with authored ABC beam grouping in 4/4" do
      it "beams eight adjacent eighths as one group, spanning all beats" do
        composition = HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/8\nK:C\nCDEFGABc |]\n")
        document = parse_musicxml(described_class.new(composition).to_s)
        expect(xpath_texts(document, "//measure[@number='1']/note/beam[@number='1']"))
          .to eq %w[begin continue continue continue continue continue continue end]
      end

      it "breaks beams at authored spaces into one group per spaced pair" do
        composition = HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/8\nK:C\nCD EF GA Bc |]\n")
        document = parse_musicxml(described_class.new(composition).to_s)
        expect(xpath_texts(document, "//measure[@number='1']/note/beam[@number='1']"))
          .to eq %w[begin end begin end begin end begin end]
      end
    end

    context "with a quarter note breaking two eighth runs in 4/4" do
      let(:composition) { HeadMusic::Notation::ABC.parse("X:1\nT:Beams\nM:4/4\nL:1/8\nK:C\nCD E2 FG A2 |]\n") }
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "emits no beam on the quarter notes" do
        expect(xpath_count(document, "//measure[@number='1']/note[type='quarter']/beam")).to eq 0
      end

      it "beams the eighths on each side as separate groups" do
        expect(xpath_texts(document, "//measure[@number='1']/note/beam[@number='1']"))
          .to eq %w[begin end begin end]
      end
    end

    context "with a rest breaking two eighth runs in 4/4" do
      let(:composition) { HeadMusic::Notation::ABC.parse("X:1\nT:Beams\nM:4/4\nL:1/8\nK:C\nCD z2 EF z2 |]\n") }
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "emits no beam on the rests" do
        expect(xpath_count(document, "//measure[@number='1']/note[rest]/beam")).to eq 0
      end

      it "beams the eighths on each side as separate groups" do
        expect(xpath_texts(document, "//measure[@number='1']/note/beam[@number='1']"))
          .to eq %w[begin end begin end]
      end
    end

    context "with a chord of default-beamed eighths" do
      let(:composition) do
        HeadMusic::Content::Composition.new(meter: "2/4").tap do |composition|
          voice = composition.add_voice
          [%w[C4 E4], %w[D4 F4], %w[E4 G4], %w[F4 A4]].each do |pitches|
            voice.place(voice.next_position, :eighth, pitches)
          end
        end
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "beams only the lead note of each chord, never a chord member" do
        expect(xpath_count(document, "//measure[@number='1']/note[chord]/beam")).to eq 0
        expect(xpath_texts(document, "//measure[@number='1']/note[not(chord)]/beam[@number='1']"))
          .to eq %w[begin end begin end]
      end
    end

    context "with a lone eighth followed by a longer note" do
      let(:composition) { HeadMusic::Notation::ABC.parse("X:1\nT:Beams\nM:2/4\nL:1/8\nK:C\nC F3 |]\n") }
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "emits no beam on the lone eighth" do
        expect(xpath_count(document, "//measure[@number='1']/note/beam")).to eq 0
      end
    end

    context "with beamed notes carrying dots" do
      let(:xml) { described_class.new(HeadMusic::Notation::ABC.parse("X:1\nT:Beams\nM:2/4\nL:1/16\nK:C\nC3D E3F |]\n")).to_s }
      let(:first_note) { xml[/<note>.*?<\/note>/m] }
      let(:beam_index) { first_note.index(%(<beam number="1">begin</beam>)) }

      it "orders <beam> after <dot> and <type> and before </note>" do
        preceding = %w[<type>eighth</type> <dot/>].map { |element| first_note.index(element) }
        expect(preceding.all? { |index| index < beam_index }).to be true
        expect(beam_index).to be < first_note.index("</note>")
      end
    end

    # A placement whose rhythmic_value is a tied chain expands into one <note>
    # per link, and beams must attach per-component while the tie renders
    # alongside. The authored beam_break_before flag applies to link 0 only.
    context "with a tied chain of two eighths inside one beat group" do
      let(:composition) do
        HeadMusic::Content::Composition.new(meter: "2/4").tap do |composition|
          voice = composition.add_voice
          value = HeadMusic::Rudiment::RhythmicValue.new(
            :eighth, tied_value: HeadMusic::Rudiment::RhythmicValue.get(:eighth)
          )
          voice.place(voice.next_position, value, "A4")
          voice.place(voice.next_position, :quarter, "B4")
        end
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "beams the two tied links together, spanning both components" do
        expect(xpath_texts(document, "//measure[@number='1']/note/beam[@number='1']"))
          .to eq %w[begin end]
      end

      it "renders the tie and its notation alongside the beams" do
        starts = [1, 2].map { |nth| xpath_count(document, "//note[#{nth}]/tie[@type='start']") }
        stops = [1, 2].map { |nth| xpath_count(document, "//note[#{nth}]/tie[@type='stop']") }
        expect(starts).to eq [1, 0]
        expect(stops).to eq [0, 1]
        expect(xpath_count(document, "//note/notations/tied")).to eq 2
      end

      it "carries a beam and a tied notation on the same note" do
        expect(xpath_count(document, "//note[1][beam][notations/tied]")).to eq 1
        expect(xpath_count(document, "//note[2][beam][notations/tied]")).to eq 1
      end
    end

    # A pickup written out with leading rests still numbers onsets from the bar
    # start, so beam grouping must follow each note's true onset, not its offset
    # in the placement list. A dotted-quarter rest makes the grouping
    # non-periodic: onset-0 grouping would beam a different pair.
    context "with a pickup bar whose beamed notes fall after a dotted-quarter rest" do
      let(:composition) do
        HeadMusic::Content::Composition.new(meter: "4/4").tap do |composition|
          voice = composition.add_voice
          voice.place("0:1", HeadMusic::Rudiment::RhythmicValue.new(:quarter, dots: 1))
          5.times { voice.place(voice.next_position, :eighth, "G4") }
          voice.place("1:1", :whole, "C4")
        end
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "marks the pickup measure implicit" do
        expect(xpath_count(document, "//measure[@number='0'][@implicit='yes']")).to eq 1
      end

      it "groups the pickup eighths by their true onset, leaving the first lone" do
        expect(xpath_texts(document, "//measure[@number='0']/note/beam[@number='1']"))
          .to eq %w[begin end begin end]
        expect(xpath_count(document, "//measure[@number='0']/note[2]/beam")).to eq 0
      end

      it "lets no beam cross into the following bar" do
        expect(xpath_count(document, "//measure[@number='1']/note/beam")).to eq 0
      end
    end

    # 3/8 is a simple meter whose whole bar is one beam group (the beam group
    # unit is the dotted quarter), so three eighths beam as a single group.
    context "with three default-beamed eighths in 3/8" do
      let(:composition) do
        HeadMusic::Content::Composition.new(meter: "3/8").tap do |composition|
          voice = composition.add_voice
          3.times { voice.place(voice.next_position, :eighth, "C4") }
        end
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "beams all three eighths as one whole-bar group" do
        expect(xpath_texts(document, "//measure[@number='1']/note/beam[@number='1']"))
          .to eq %w[begin continue end]
      end

      it "never breaks the group inside the bar" do
        expect(xpath_count(document, "//measure[@number='1']/note/beam[@number='1'][.='begin']")).to eq 1
        expect(xpath_count(document, "//measure[@number='1']/note/beam[@number='1'][.='end']")).to eq 1
      end
    end

    context "with eight default-beamed eighths, checking group adjacency in 4/4" do
      let(:composition) do
        HeadMusic::Content::Composition.new(meter: "4/4").tap do |composition|
          voice = composition.add_voice
          8.times { voice.place(voice.next_position, :eighth, "C4") }
        end
      end
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }
      let(:beams) { xpath_texts(document, "//measure[@number='1']/note/beam[@number='1']") }

      it "abuts a group's end directly against the next group's begin, never continuing" do
        expect(beams).to eq %w[begin end begin end begin end begin end]
        beams.each_cons(2) { |pair| expect(pair).not_to eq %w[continue continue] }
        beams.each_slice(2) { |pair| expect(pair).to eq %w[begin end] }
      end
    end

    context "with authored back-to-back four-note groups in 4/4" do
      let(:composition) { HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/8\nK:C\nCCCC CCCC |]\n") }
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "honors the authored mid-bar space, beaming two four-note groups" do
        expect(xpath_texts(document, "//measure[@number='1']/note/beam[@number='1']"))
          .to eq %w[begin continue continue end begin continue continue end]
      end
    end

    # An authored space can subdivide within a single dotted-quarter pulse: the
    # lone note between two beamed runs gets no beam at all.
    context "with an authored split below the pulse in 6/8" do
      let(:composition) { HeadMusic::Notation::ABC.parse("X:1\nM:6/8\nL:1/8\nK:C\nab c def |]\n") }
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "beams the pair, leaves the lone note bare, and beams the triple" do
        expect(xpath_texts(document, "//measure[@number='1']/note/beam[@number='1']"))
          .to eq %w[begin end begin continue end]
      end

      it "emits no beam on the lone middle note" do
        expect(xpath_count(document, "//measure[@number='1']/note[3]/beam")).to eq 0
      end
    end

    # A dotted-eighth + sixteenth pair must survive the full writer path with
    # both beam levels intact: the sixteenth ends level 1 and hooks level 2.
    context "with a dotted-eighth and sixteenth pair in 2/4" do
      let(:composition) { HeadMusic::Notation::ABC.parse("X:1\nM:2/4\nL:1/16\nK:C\nC3D |]\n") }
      let(:document) { parse_musicxml(described_class.new(composition).to_s) }

      it "carries the level-1 end and the level-2 backward hook on the sixteenth" do
        expect(xpath_text(document, "//measure[@number='1']/note[2]/beam[@number='1']")).to eq "end"
        expect(xpath_text(document, "//measure[@number='1']/note[2]/beam[@number='2']")).to eq "backward hook"
      end

      it "begins the level-1 beam on the dotted eighth" do
        expect(xpath_text(document, "//measure[@number='1']/note[1]/beam[@number='1']")).to eq "begin"
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
