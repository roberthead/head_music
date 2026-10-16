require "spec_helper"

# MEI made outside head_music: MuseScore 4's exports of the gem's MusicXML
# renders, two Bach chorales from the MEI sample encodings, and music21's
# test files; see the READMEs in spec/fixtures/notation/mei/musescore/ and
# spec/fixtures/notation/mei/real/ for where each comes from.
describe HeadMusic::Notation::MEI do
  def parse_file(path)
    described_class.parse(File.binread(path))
  end

  def real_path(*names)
    File.join(MEIFixtures::DIRECTORY, "real", *names)
  end

  def export_path(name)
    File.join(MEIFixtures::DIRECTORY, "musescore", "#{name}.musescore4.mei")
  end

  def summary(flow)
    mei_music(flow).except("work")
  end

  describe "MuseScore 4 exports" do
    # What MuseScore changes that reads back differently, by file. The rest
    # of what the README lists reads back the same: random ids, layout
    # elements, the meter and key moved onto each <staffDef>, <tie> control
    # events, <accid> and <artic> children, the left hand as a layer of the
    # upper staff, the segno and coda as glyphs, note dynamics as <dynam>s,
    # and a clef change written at the end of the bar before.
    #
    # - added_piano_sound: an instrumentless part gets midi.instrnum 0, the
    #   piano.
    # - directions_on_staff: every <dynam> and <hairpin> names a staff and
    #   no layer, so a voice's levels read back as its part's.
    # - hairpins_dropped: no hairpin has an end, so none reads back.
    # - levels_between_notes_dropped: a level where no note starts is gone.
    # - final_hairpin_dropped: the hairpin to the final barline has no end.
    # - navigation_words_dropped: Fine, To Coda, D.C., and D.S. are gone.
    # - pickup_as_bar_one: the pickup has no @n and no type="upbeat", and is
    #   as long as a bar, so the music reads one bar later.
    changes = {
      "speed_the_plough" => %i[added_piano_sound],
      "bach_invention_01" => %i[added_piano_sound],
      "cross_staff_piano" => [],
      "piano_part_marks" => %i[directions_on_staff hairpins_dropped levels_between_notes_dropped],
      "marked_dal_segno_al_coda" => %i[added_piano_sound final_hairpin_dropped navigation_words_dropped],
      "marked_da_capo_al_fine" => %i[added_piano_sound navigation_words_dropped],
      "barline_styles" => %i[added_piano_sound navigation_words_dropped],
      "key_and_meter_change" => %i[added_piano_sound],
      "clef_changes" => %i[added_piano_sound],
      "triplets" => %i[added_piano_sound],
      "grace_notes_before_downbeat" => %i[added_piano_sound],
      "two_verses" => %i[added_piano_sound pickup_as_bar_one],
      "clarinet_changes" => []
    }

    def source(name)
      HeadMusic::Notation::MusicXML.parse(File.read(MuseScoreFixtures.path(name, "head_music")))
    end

    # The source's summary with each listed change made, and the export's,
    # with direction ownership made the part's in both.
    def comparable(ours, theirs, listed)
      expected = listed.reduce(summary(ours)) { |changed, change| send(change, changed, ours) }
      actual = summary(theirs)
      return [expected, actual] unless listed.include?(:directions_on_staff)

      [directions_by_part(expected), directions_by_part(actual)]
    end

    def added_piano_sound(summary, _flow)
      summary.merge("parts" => summary["parts"].map { |part| part.key?("instrument") ? part : part.merge("instrument" => "piano") })
    end

    def directions_on_staff(summary, _flow)
      summary
    end

    def hairpins_dropped(summary, _flow)
      without_hairpins(summary) { true }
    end

    def final_hairpin_dropped(summary, flow)
      final = flow.final_barline_position.to_s
      without_hairpins(summary) { |span| span["to"] == final }
    end

    def without_hairpins(summary, &dropped)
      keep = ->(owner) { owner.merge("spans" => owner["spans"].to_a.reject { |span| hairpin?(span) && dropped.call(span) }).reject { |key, value| key == "spans" && value.empty? } }
      summary.merge("parts" => summary["parts"].map { |part| keep.call(part).merge("voices" => part["voices"].map(&keep)) })
    end

    def levels_between_notes_dropped(summary, flow)
      onsets = flow.voices.flat_map { |voice| voice.voice_events.map { |voice_event| voice_event.position.to_s } }
      keep = ->(owner) { owner.merge("dynamic_events" => owner["dynamic_events"].to_a.select { |level| onsets.include?(level["position"]) }).reject { |key, value| key == "dynamic_events" && value.empty? } }
      summary.merge("parts" => summary["parts"].map { |part| keep.call(part).merge("voices" => part["voices"].map(&keep)) })
    end

    def navigation_words_dropped(summary, _flow)
      bars = summary["bars"].map { |bar| bar.except("fine", "to_coda", "jump") }.reject { |bar| bar.keys == ["number"] }
      summary.merge("bars" => bars)
    end

    def pickup_as_bar_one(summary, _flow)
      later(summary)
    end

    # Every position and bar number one bar later.
    def later(value, key = nil)
      case value
      when Hash then value.to_h { |name, inner| [name, later(inner, name)] }
      when Array then value.map { |inner| later(inner, key) }
      when String then value.sub(/\A(\d+)(?=:\d+:\d+)/) { (Integer(Regexp.last_match(1), 10) + 1).to_s }
      when Integer then (key == "number") ? value + 1 : value
      else value
      end
    end

    def hairpin?(span)
      %w[crescendo diminuendo].include?(span["kind"])
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

    it "lists what MuseScore changes for every export but the transposed one" do
      expect(changes.keys).to eq MuseScoreFixtures.names - %w[clarinet_changes_transposed]
    end

    it "commits an export of every MusicXML fixture, and only those" do
      committed = Dir[File.join(MEIFixtures::DIRECTORY, "musescore", "*.musescore4.mei")].map { |path| File.basename(path, ".musescore4.mei") }
      expect(committed).to match_array MuseScoreFixtures.names
    end

    changes.each do |name, listed|
      it "reads #{name} as the MusicXML it was exported from#{" but for #{listed.join(", ")}" unless listed.empty?}" do
        expected, actual = comparable(source(name), parse_file(export_path(name)), listed)
        expect(actual).to eq expected
      end

      it "keeps the music of #{name} whole" do
        expect_mei_music_whole(parse_file(export_path(name)))
      end
    end

    describe "clarinet_changes_transposed" do
      let(:ours) { source("clarinet_changes_transposed") }
      let(:theirs) { parse_file(export_path("clarinet_changes_transposed")) }

      def semitones(flow)
        flow.voices.first.note_events.map { |note_event| note_event.pitches.first.midi_note_number }
      end

      # MuseScore states the B-flat clarinet's @trans.* once, so the A
      # clarinet's bars read a semitone high and the flute's a tone low.
      it "reads the bars after the first instrument change as MuseScore's one transposition leaves them" do
        offsets = semitones(theirs).zip(semitones(ours)).map { |their, our| their - our }
        expect(offsets).to eq [0, 0, 1, 1, -2, -2]
      end

      it "reads the opening written key at concert pitch, and each later <scoreDef keysig> as a concert key" do
        expect([theirs.key_signature.name, theirs.key_signature_changes.transform_values(&:to_s)]).to eq ["C major", {3 => "-3 E♭ major", 5 => "0 C major"}]
      end

      it "reads everything else as the MusicXML it was exported from" do
        summaries = [ours, theirs].map do |flow|
          mei_music(flow).then { |music| music.merge("timeline" => music["timeline"].except("key_signature_changes"), "parts" => music["parts"].map { |part| part.except("voices") }) }
        end
        expect(summaries.last).to eq summaries.first
      end
    end

    describe "re-exported by the MuseScore installed here" do
      regenerating = MuseScore.available? && (!ENV["MSCORE"].to_s.empty? || ENV["MUSESCORE_FIXTURES"] == "1")

      before { skip "set MSCORE, or MUSESCORE_FIXTURES=1 with MuseScore 4 installed, to check for drift" unless regenerating }

      # Compared as flows rather than bytes, since MuseScore gives every
      # export new ids and the moment of the conversion.
      MuseScoreFixtures.names.each do |name|
        it "reads #{name} as the committed export" do
          Dir.mktmpdir("mei") do |directory|
            target = File.join(directory, "#{name}.musescore4.mei")
            MuseScore.convert_file(MuseScoreFixtures.path(name, "head_music"), target, timeout: 120)
            expect(parse_file(target).to_h).to eq parse_file(export_path(name)).to_h
          end
        end
      end
    end
  end

  describe "the Bach chorales from the MEI sample encodings" do
    def opening(flow)
      flow.voices.map { |voice| voice.note_events.first(2).map { |note_event| note_event.pitches.map(&:to_s) } }
    end

    def bar_range(flow)
      bars = flow.voices.flat_map { |voice| voice.voice_events.map { |voice_event| voice_event.position.bar_number } }
      bars.minmax
    end

    describe "Herzliebster Jesu" do
      let(:flow) { parse_file(real_path("Bach-JS_Herzliebster_Jesu_BWV244-46.mei")) }

      it "reads its title, work, and composer, ignoring the incipit in its head" do
        expect([flow.name, flow.work.title, flow.work.composer]).to eq ["Herzliebster Jesu, was hast du verbrochen"] * 2 + ["Johann Sebastian Bach"]
      end

      it "reads four parts of one voice each, through bars 0 to 11, in D major and 4/4" do
        shape = [flow.parts.map { |part| part.voices.length }, bar_range(flow), flow.key_signature.name, flow.meter.to_s]
        expect(shape).to eq [[1, 1, 1, 1], [0, 11], "D major", "4/4"]
      end

      it "reads the opening pitches of each voice after the pickup's rest" do
        expect(opening(flow)).to eq [[["B4"], ["B4"]], [["A4"], ["G4"]], [["F♯4"], ["E4"]], [["D♯3"], ["E3"]]]
      end

      it "keeps the music whole" do
        expect_mei_music_whole(flow)
      end
    end

    describe "Ein feste Burg" do
      let(:flow) { parse_file(real_path("Bach-JS_Ein_feste_Burg.mei")) }

      it "reads its two braced staves as one part of four voices, a layer of each staff each" do
        part = flow.parts.first
        staves = part.voices.map { |voice| part.staff_system.staves.index(voice.staff_at(1)) + 1 }
        expect([flow.parts.length, part.staff_system.staves.length, staves]).to eq [1, 2, [1, 1, 2, 2]]
      end

      it "reads bars 0 to 12 in D major and 4/4, with the repeat at bar 4" do
        expect([bar_range(flow), flow.key_signature.name, flow.meter.to_s, flow.to_h["bars"]]).to eq [[0, 12], "D major", "4/4", [{"number" => 4, "ends_repeat_after_num_plays" => 2}]]
      end

      it "reads the opening pitches of each voice after the pickup's rest" do
        expect(opening(flow)).to eq [[["D5"], ["D5"]], [["A4"], ["D4"]], [["F♯4"], ["F♯4"]], [["D4"], ["C♯4"]]]
      end

      it "reads both verses of the soprano's lyrics" do
        syllables = flow.voices.first.voice_events.map { |voice_event| voice_event.syllables.transform_values(&:text) }.reject(&:empty?)
        expect(syllables.first(3)).to eq [{1 => "Ein´", 2 => "Er"}, {1 => "fe", 2 => "hilft"}, {1 => "ste", 2 => "uns"}]
      end

      it "reads its slurs, placed by ids and beats both, by their ids" do
        slurs = flow.voices.flat_map(&:spans).select { |span| span.kind == :slur }
        expect([slurs.length, slurs.first(2).map(&:to_s)]).to eq [11, ["slur from 5:1:000 to 5:2:000", "slur from 11:3:000 to 12:1:000"]]
      end

      it "keeps the music whole" do
        expect_mei_music_whole(flow)
      end
    end
  end

  describe "music21's test files" do
    def music21_path(name)
      real_path("music21", name)
    end

    it "reads notes_in_utf8.mei and its UTF-16 copy alike, through 26 bars" do
      flows = %w[notes_in_utf8.mei notes_in_utf16.mei].map { |name| parse_file(music21_path(name)) }
      expect([flows.first.to_h == flows.last.to_h, flows.first.name, flows.first.voices.first.voice_events.last.position.bar_number])
        .to eq [true, "Pitches and accidentals", 26]
    end

    it "keeps the music of notes_in_utf8.mei whole" do
      expect_mei_music_whole(parse_file(music21_path("notes_in_utf8.mei")))
    end

    # Its <score> sits straight in <music>, which reads as one division, but
    # it then writes <layer n="">, which no MEI version allows; past that it
    # writes upper-case @pname and nested tuplets.
    it "refuses test_file.mei for its empty layer number, past its score straight in <music>" do
      expect { parse_file(music21_path("test_file.mei")) }.to raise_error(described_class::ParseError, /Unreadable @n "" \(measure 6, staff 2, <layer>\)/)
    end
  end
end
