require "spec_helper"

# Files from other scorewriters: MuseScore 4's conversions of the gem's own
# renders, the LilyPond MusicXML test suite, and score-timewise conversions;
# see spec/fixtures/notation/music_xml/README.md for where each comes from.
describe HeadMusic::Notation::MusicXML do
  def parse_file(path)
    described_class.parse(File.binread(path))
  end

  def suite_path(name)
    File.join(MuseScoreFixtures::DIRECTORY, "lilypond_test_suite", "#{name}.xml")
  end

  describe "MuseScore 4 conversions" do
    # What MuseScore changes that reads back differently, by fixture. The
    # rest of what the README lists reads back the same: the dropped
    # <mode>major of C, note dynamics moved into directions, the navigation
    # signs written as glyph words, hairpin stops moved to the end of the
    # bar before, a left hand renumbered voice 5, the hidden rests of a voice
    # 5 beside a crossing left hand, which do not print and so read as
    # nothing, and instrument changes, which neither rendering writes.
    #
    # - added_piano_sound: an instrumentless part gets keyboard.piano.grand.
    # - directions_on_staff: every direction loses its <voice>, so a voice's
    #   levels and hairpins read back as its part's, at the same moments.
    changes = {
      "speed_the_plough" => %i[added_piano_sound],
      "bach_invention_01" => %i[added_piano_sound],
      "cross_staff_piano" => [],
      "piano_part_marks" => %i[directions_on_staff],
      "marked_dal_segno_al_coda" => %i[added_piano_sound],
      "marked_da_capo_al_fine" => %i[added_piano_sound],
      "barline_styles" => %i[added_piano_sound],
      "key_and_meter_change" => %i[added_piano_sound],
      "clef_changes" => %i[added_piano_sound],
      "triplets" => %i[added_piano_sound],
      "grace_notes_before_downbeat" => %i[added_piano_sound],
      "two_verses" => %i[added_piano_sound],
      "clarinet_changes" => []
    }

    def music(kind, name)
      musicxml_music(parse_file(MuseScoreFixtures.path(name, kind)))
    end

    # Undoes each listed change in MuseScore's reading, or for direction
    # ownership, compares both readings by part.
    def comparable(ours, theirs, changes)
      theirs = added_piano_sound(ours, theirs) if changes.include?(:added_piano_sound)
      return [ours, theirs] unless changes.include?(:directions_on_staff)

      [directions_by_part(ours), directions_by_part(theirs)]
    end

    def added_piano_sound(ours, theirs)
      parts = theirs["parts"].zip(ours["parts"]).map do |part, our_part|
        (part["instrument"] == "piano" && !our_part.key?("instrument")) ? part.except("instrument") : part
      end
      theirs.merge("parts" => parts)
    end

    # Every level and hairpin of a part and its voices, as its part's.
    def directions_by_part(summary)
      parts = summary["parts"].map do |part|
        voices = part["voices"].map { |voice| voice.except("dynamic_events").merge("spans" => voice["spans"].to_a.reject { |span| hairpin?(span) }) }
        moved = part["voices"].flat_map { |voice| [voice["dynamic_events"].to_a, voice["spans"].to_a.select { |span| hairpin?(span) }] }
        part.merge(
          "dynamic_events" => (part["dynamic_events"].to_a + moved.each_slice(2).flat_map(&:first)).sort_by(&:to_a),
          "spans" => (part["spans"].to_a + moved.each_slice(2).flat_map(&:last)).sort_by(&:to_a),
          "voices" => voices.map { |voice| voice["spans"].empty? ? voice.except("spans") : voice }
        )
      end
      summary.merge("parts" => parts)
    end

    it "lists what MuseScore changes for every conversion but the transposed one" do
      expect(changes.keys).to eq MuseScoreFixtures.names - %w[clarinet_changes_transposed]
    end

    changes.each do |name, listed|
      it "reads #{name} as the render it converted#{" but for #{listed.join(", ")}" unless listed.empty?}" do
        ours, theirs = comparable(music("head_music", name), music("musescore4", name), listed)
        expect(theirs).to eq ours
      end

      it "keeps the music of #{name} whole" do
        expect_music_whole(parse_file(MuseScoreFixtures.path(name, "musescore4")))
      end
    end

    describe "clarinet_changes_transposed" do
      let(:ours) { parse_file(MuseScoreFixtures.path("clarinet_changes_transposed", "head_music")) }
      let(:theirs) { parse_file(MuseScoreFixtures.path("clarinet_changes_transposed", "musescore4")) }

      def semitones(flow)
        flow.voices.first.note_events.map { |note_event| note_event.pitches.first.midi_note_number }
      end

      # MuseScore keeps only the B-flat clarinet's <transpose>, so the A
      # clarinet's bars read a semitone high and the flute's a tone low.
      it "reads the bars after the first instrument change as MuseScore's one <transpose> leaves them" do
        offsets = semitones(theirs).zip(semitones(ours)).map { |their, our| their - our }
        expect(offsets).to eq [0, 0, 1, 1, -2, -2]
      end

      it "reads each written key change as a change of concert key under the B-flat <transpose>" do
        expect(theirs.key_signature_changes.transform_values(&:to_s)).to eq(3 => "-5 D♭ major", 5 => "-2 B♭ major")
      end

      it "reads everything else as the render it converted" do
        summaries = [ours, theirs].map do |flow|
          summary = musicxml_music(flow)
          summary.merge("timeline" => summary["timeline"].except("key_signature_changes"), "parts" => summary["parts"].map { |part| part.except("voices") })
        end
        expect(summaries.last).to eq summaries.first
      end
    end

    describe "reconverted by the MuseScore installed here", oracle: :musescore do
      # Compared as flows rather than bytes, since MuseScore stamps the day
      # of the conversion in <encoding-date>.
      MuseScoreFixtures.names.each do |name|
        it "reads #{name} as the committed conversion" do
          converted = MuseScore.convert(File.read(MuseScoreFixtures.path(name, "head_music")))
          expect(described_class.parse(converted).to_h).to eq parse_file(MuseScoreFixtures.path(name, "musescore4")).to_h
        end
      end
    end
  end

  describe "the LilyPond MusicXML test suite" do
    def syllables(flow, count)
      flow.voices.first.voice_events.map { |voice_event| voice_event.syllables.transform_values(&:text) }.reject(&:empty?).first(count)
    end

    def all_spans(flow)
      flow.parts.flat_map { |part| [part, *part.voices] }.flat_map(&:spans).map(&:to_s)
    end

    readable = {
      "31a-Directions" => ->(flow) { [flow.bars(2).map(&:to_h), flow.parts.first.dynamic_events.first(3).map(&:to_s)] },
      "32a-Notations" => ->(flow) { flow.voices.first.voice_events.flat_map { |event| event.articulations.map(&:name_key) }.uniq },
      "33c-Spanners-Slurs" => ->(flow) { all_spans(flow).first(3) },
      "42b-MultiVoice-MidMeasureClefChange" => ->(flow) { [flow.voices.length, flow.parts.first.staff_system.staves.first.clef_changes] },
      "45b-RepeatWithAlternatives" => ->(flow) { flow.to_h["bars"] },
      "45c-RepeatMultipleTimes" => ->(flow) { flow.to_h["bars"] },
      "46a-Barlines" => ->(flow) { flow.to_h["bars"].first(4) },
      "46c-Midmeasure-Clef" => ->(flow) { [voice_event_strings(flow).first.first(2), flow.parts.first.staff_system.staves.first.clef_changes] },
      "61a-Lyrics" => ->(flow) { syllables(flow, 4) },
      "61b-MultipleLyrics" => ->(flow) { syllables(flow, 2) },
      "61g-Lyrics-NameNumber" => ->(flow) { syllables(flow, 3) },
      "61j-Lyrics-Elisions" => ->(flow) { syllables(flow, 4) },
      "99a-Sibelius5-IgnoreBeaming" => ->(flow) { [voice_event_strings(flow).first.first(3), all_spans(flow)] }
    }

    expected = {
      "31a-Directions" => [[{"rehearsal_mark" => "A"}, {"segno" => true, "coda" => true}], ["p at 3:1:000", "pp at 3:2:000", "ppp at 3:3:000"]],
      "32a-Notations" => %w[accent marcato staccato tenuto staccatissimo],
      "33c-Spanners-Slurs" => ["slur from 1:1:000 to 1:2:000", "slur from 1:2:000 to 1:3:000", "slur from 1:3:000 to 1:4:000"],
      "42b-MultiVoice-MidMeasureClefChange" => [2, {}],
      "45b-RepeatWithAlternatives" => [{"number" => 2, "ends_repeat_after_num_plays" => 2, "plays_on_passes" => [1]}, {"number" => 3, "plays_on_passes" => [2]}],
      "45c-RepeatMultipleTimes" => [{"number" => 2, "starts_repeat" => true}, {"number" => 3, "ends_repeat_after_num_plays" => 5}, {"number" => 7, "ends_repeat_after_num_plays" => 3}],
      "46a-Barlines" => [{"number" => 3, "barline" => "dotted"}, {"number" => 4, "barline" => "dashed"}, {"number" => 6, "barline" => "double"}, {"number" => 7, "barline" => "final"}],
      "46c-Midmeasure-Clef" => [["whole rest at 1:1:000", "quarter C5 at 2:1:000"], {}],
      "61a-Lyrics" => [{1 => "Tra"}, {1 => "la"}, {1 => "li"}, {1 => "Ja!"}],
      "61b-MultipleLyrics" => [{1 => "1.Tra", 2 => "2.tra", 3 => "3.TRA"}, {1 => "la", 2 => "la", 3 => "LA"}],
      "61g-Lyrics-NameNumber" => [{1 => "Verse1A", 2 => "Chorus1A"}, {1 => "1B", 2 => "2B"}, {1 => "Verse1C", 2 => "Chorus2C"}],
      "61j-Lyrics-Elisions" => [{1 => "a"}, {1 => "b c"}, {1 => "d‿e"}, {1 => "f‿g‿h"}],
      "99a-Sibelius5-IgnoreBeaming" => [
        ["triple-dotted quarter rest at 1:1:000", "thirty-second E6 at 1:2:840", "thirty-second F♯6 at 1:3:000"], ["slur from 1:2:840 to 1:3:840"]
      ]
    }

    # 41g leaves out <divisions>, which the story makes a ParseError, before
    # the missing part id it was written to test can matter.
    refused = {"41g-PartNoId" => [described_class::ParseError, /no <divisions> in force \(measure 1\)/]}

    it "covers every committed file" do
      names = Dir[File.join(MuseScoreFixtures::DIRECTORY, "lilypond_test_suite", "*.xml")].map { |path| File.basename(path, ".xml") }
      expect((readable.keys + refused.keys).sort).to eq names.sort
    end

    readable.each do |name, read|
      it "reads #{name} end to end" do
        flow = parse_file(suite_path(name))
        expect_music_whole(flow)
        expect(instance_exec(flow, &read)).to eq expected.fetch(name)
      end
    end

    refused.each do |name, (error_class, message)|
      it "refuses #{name}" do
        expect { parse_file(suite_path(name)) }.to raise_error(error_class, message)
      end
    end
  end

  describe "score-timewise conversions" do
    MuseScoreFixtures::TIMEWISE.each do |name|
      it "reads #{name} as its partwise source" do
        expect(parse_file(MuseScoreFixtures.path(name, "timewise")).to_h).to eq parse_file(MuseScoreFixtures.path(name, "head_music")).to_h
      end
    end
  end

  it "commits the renders the gem writes today" do
    stale = MuseScoreFixtures.names.reject { |name| MuseScoreFixtures.musicxml(name) == File.read(MuseScoreFixtures.path(name, "head_music")) }
    expect(stale).to eq []
  end
end
