require "spec_helper"

describe HeadMusic::Notation::LilyPond::Writer do
  describe "#to_s" do
    context "with a single-voice diatonic tune" do
      let(:flow) { LilyPondFixtures.speed_the_plough }
      let(:rendered) { described_class.new(flow).to_s }

      it "is structurally valid" do
        expect_structurally_valid_lilypond(rendered, bars: 8, voices: 1)
      end

      it "carries the title in the header" do
        expect(rendered).to include %(title = "Speed the Plough")
      end

      it "emits the key and time before the first bar" do
        expect(rendered).to include "\\key g \\major\n", "\\time 4/4\n"
      end

      it "selects the treble clef" do
        expect(rendered).to include "\\clef treble"
      end

      it "renders the opening bar in order with a bar check" do
        expect(bar_check_lines(rendered).first).to eq "g'8 a'8 b'8 c''8 d''8 e''8 d''8 b'8 |"
      end
    end

    context "with a tune with accidentals" do
      let(:flow) { LilyPondFixtures.chromatic_air }
      let(:rendered) { described_class.new(flow).to_s }

      it "is structurally valid" do
        expect_structurally_valid_lilypond(rendered, bars: 4, voices: 1)
      end

      it "carries the composer in the header" do
        expect(rendered).to include %(composer = "Trad.")
      end

      it "spells sharps with the is suffix" do
        expect(bar_check_lines(rendered).first).to start_with "a'8 gis'8 a'8 g'8"
      end

      it "spells flats with the es suffix" do
        expect(bar_check_lines(rendered)[1]).to start_with "bes'8"
      end
    end

    context "with rests" do
      let(:flow) { LilyPondFixtures.rests }
      let(:rendered) { described_class.new(flow).to_s }

      it "is structurally valid" do
        expect_structurally_valid_lilypond(rendered, bars: 1, voices: 1)
      end

      it "renders the rest between the notes" do
        expect(bar_check_lines(rendered)).to eq [%(c'4 r4 e'2 \\bar "|." |)]
      end
    end

    context "with multiple voices" do
      let(:flow) { LilyPondFixtures.duo }
      let(:rendered) { described_class.new(flow).to_s }

      it "is structurally valid" do
        expect_structurally_valid_lilypond(rendered, bars: 2, voices: 2)
      end

      it "emits one staff per voice, in flow order" do
        names = rendered.scan(/instrumentName = "([^"]+)"/).flatten
        expect(names).to eq ["Melody", "Bass line"]
      end

      it "selects the bass clef for the low voice" do
        expect(rendered.scan(/\\clef (\w+)/).flatten).to eq %w[treble bass]
      end

      it "fills the short voice's missing bar with a whole-bar rest" do
        expect(bar_check_lines(rendered).last).to eq %(R1*4/4 \\bar "|." |)
      end

      it_behaves_like "a compilable document"
    end

    # Soprano and alto sharing a staff is the ordinary two-voice-one-part
    # shape, and it renders as one staff, as MusicXML renders the same part.
    context "with two voices sharing one staff" do
      let(:flow) do
        HeadMusic::Content::Flow.new(name: "Shared Staff").tap do |flow|
          part = flow.add_part(instrument: "piano")
          soprano = part.add_voice(role: "soprano")
          alto = part.add_voice(role: "alto")
          (1..2).each do |bar|
            soprano.place("#{bar}:1", :whole, "E5")
            alto.place("#{bar}:1", :whole, "C5")
          end
        end
      end
      let(:rendered) { described_class.new(flow).to_s }

      it "emits one staff" do
        expect(rendered.scan("\\new Staff").length).to eq 1
      end

      it "names the staff for the part rather than either voice" do
        expect(rendered).to match(/\\new Staff \\with \{ instrumentName = "piano" \} <</i)
      end

      it "emits a voice per voice in parallel" do
        expect(rendered.scan("\\new Voice").length).to eq 2
      end

      it "carries a stream per voice" do
        expect_structurally_valid_lilypond(rendered, bars: 2, voices: 2)
      end

      it_behaves_like "a compilable document"
    end

    # A tacet chair keeps its line in the score rather than vanishing.
    context "with a part that has no voices" do
      let(:flow) do
        HeadMusic::Content::Flow.new(name: "Tacet").tap do |flow|
          flow.add_voice(role: "Flute").place("1:1", :whole, "E5")
          flow.add_part(instrument: "oboe")
        end
      end
      let(:rendered) { described_class.new(flow).to_s }

      it "emits a staff for the voiceless part, named for its instrument" do
        expect(rendered.scan("\\new Staff").length).to eq 2
        expect(rendered).to match(/instrumentName = "oboe"/i)
      end

      it "fills it with whole-bar rests under a full opening" do
        expect(rendered).to include "\\clef treble", "\\key c \\major", "\\time 4/4"
        expect(bar_check_lines(rendered).last).to eq "R1*4/4 |"
      end

      it_behaves_like "a compilable document"
    end

    context "with an authored clef other than treble or bass" do
      def rendered_with(clef)
        HeadMusic::Content::Flow.new(name: "Clef").tap do |flow|
          part = flow.add_part(staff_system: HeadMusic::Content::StaffSystem.single_staff(clef: clef))
          part.add_voice.place("1:1", :whole, "C4")
        end.to_lilypond
      end

      it "writes the alto clef as alto" do
        expect(rendered_with(:alto_clef)).to include "\\clef alto"
      end

      it "writes the tenor clef as tenor" do
        expect(rendered_with(:tenor_clef)).to include "\\clef tenor"
      end

      # The octave clefs carry characters LilyPond accepts only inside quotes.
      it "writes the vocal tenor clef as a quoted octave treble" do
        expect(rendered_with(:vocal_tenor_clef)).to include %(\\clef "treble_8")
      end

      it "writes every clef the gem knows" do
        names = %i[french_violin_clef double_treble_clef soprano_clef mezzo_soprano_clef baritone_c_clef baritone_clef sub_bass_clef neutral_clef]
        expect(names.map { |name| rendered_with(name)[/\\clef (\S+)/, 1] })
          .to eq %w[french "treble^8" soprano mezzosoprano baritone varbaritone subbass percussion]
      end
    end

    context "with a mid-piece key and meter change" do
      let(:flow) { LilyPondFixtures.key_and_meter_change }
      let(:rendered) { described_class.new(flow).to_s }

      it "is structurally valid" do
        expect_structurally_valid_lilypond(rendered, bars: 3, voices: 2)
      end

      it "emits the change commands at the change bar in every voice" do
        change_lines = bar_check_lines(rendered).select { |line| line.include?("\\key d \\major \\time 3/4") }
        expect(change_lines.length).to eq 2
      end

      it "does not emit change commands at other bars" do
        other_lines = bar_check_lines(rendered).reject { |line| line.include?("\\key") }
        expect(other_lines.length).to eq 4
      end

      it_behaves_like "a compilable document"
    end

    context "with a fourth-species counterpoint" do
      let(:flow) { LilyPondFixtures.fourth_species }
      let(:rendered) { described_class.new(flow).to_s }
      let(:counterpoint_lines) { bar_check_lines(rendered).last(11) }

      it "is structurally valid" do
        expect_structurally_valid_lilypond(rendered, bars: 11, voices: 2)
      end

      it "ties each syncopation across its bar check" do
        expect(counterpoint_lines.first(3)).to eq ["r2 a'2~ |", "a'2 d''2~ |", "d''2 c''2~ |"]
      end

      it "leaves the bars without a syncopation untied" do
        expect(counterpoint_lines.values_at(4, 9)).to eq ["bes'2 g'2 |", "d''2 cis''2 |"]
      end

      it_behaves_like "a compilable document"
    end

    context "with a note tied across a key change" do
      let(:flow) { LilyPondFixtures.tie_into_key_change }
      let(:rendered) { described_class.new(flow).to_s }

      it "writes the key change between the halves of the tie" do
        expect(bar_check_lines(rendered).first(2)).to eq ["c''2 d''2~ |", %(\\key g \\major d''2 fis''2 \\bar "|." |)]
      end

      it_behaves_like "a compilable document"
    end

    context "with a note tied across a meter change" do
      let(:flow) { LilyPondFixtures.tie_into_meter_change }
      let(:rendered) { described_class.new(flow).to_s }

      it "writes the meter change between the halves of the tie" do
        expect(bar_check_lines(rendered).first(2)).to eq ["g'2 a'2~ |", "\\time 3/4 a'2 b'4 |"]
      end

      it_behaves_like "a compilable document"
    end

    context "with voices that end together in a short final bar" do
      let(:flow) { LilyPondFixtures.short_final_bar }
      let(:rendered) { described_class.new(flow).to_s }

      it "leaves the bar check off the short final bar only" do
        expect(rendered.lines.map(&:strip).grep(/\A(r2 |c'?'?2\.|b'2|g2)/))
          .to eq ["r2 g'4 |", "c''2. |", %(b'2 \\bar "|."), "r2 g4 |", "c2. |", %(g2 \\bar "|.")]
      end

      it_behaves_like "a compilable document"
    end

    context "with a pickup, a short final bar, and a tacet voice" do
      let(:flow) { LilyPondFixtures.pickup_and_short_final_bar }
      let(:rendered) { described_class.new(flow).to_s }

      it "rests the tacet voice only as long as the short final bar" do
        expect(rendered.lines.map(&:strip).each_cons(3)).to include ["R1*3/4 |", "R1*3/4 |", %(r2 \\bar "|.")]
      end

      it_behaves_like "a compilable document"
    end

    context "with a pickup, a tacet voice, and a voice dynamic after the music" do
      let(:flow) { LilyPondFixtures.pickup_and_short_final_bar.tap { |flow| flow.voices.first.place_dynamic("2:3", :f) } }
      let(:rendered) { described_class.new(flow).to_s }

      it "fills the final bar of every voice with spacers, the tacet voice's after its rest" do
        expect(bar_check_lines(rendered).grep(/\\bar/)).to eq [%(b'2 s4\\f \\bar "|." |), %(r2 s4 \\bar "|." |)]
      end

      it "compiles without warnings" do
        skip "lilypond is not installed" unless installed_lilypond

        expect(compile_warnings(rendered)).to be_empty
      end
    end

    context "with a staff nobody is written on and a part dynamic after the music" do
      let(:flow) do
        HeadMusic::Content::Flow.new(name: "Short Hand", meter: "4/4").tap do |flow|
          piano = flow.add_part(instrument: "piano", staff_system: HeadMusic::Content::StaffSystem.grand_staff)
          right_hand = piano.add_voice(role: "right hand")
          right_hand.place("1:1", :whole, "E5")
          right_hand.place("2:1", :half, "E5")
          piano.place_dynamic("2:3", :f)
        end
      end
      let(:rendered) { described_class.new(flow).to_s }

      it "writes the final bar full on every staff and in the Dynamics context" do
        expect(bar_check_lines(rendered).values_at(1, 3, 5)).to eq [%(e''2 s2 \\bar "|." |), "s2 s2\\f |", "r2 s2 |"]
      end

      it "is structurally valid" do
        expect_structurally_valid_lilypond(rendered, bars: 2, voices: 1, streams: 3)
      end

      it "compiles without warnings" do
        skip "lilypond is not installed" unless installed_lilypond

        expect(compile_warnings(rendered)).to be_empty
      end
    end

    context "with a voice's levels in a bar after its music ends" do
      let(:flow) do
        HeadMusic::Content::Flow.new(name: "Ends Early", meter: "4/4").tap do |flow|
          early = flow.add_voice(role: "upper")
          early.place("1:1", :whole, "E5")
          late = flow.add_voice(role: "lower")
          late.place("1:1", :whole, "C4")
          late.place("2:1", :whole, "D4")
          early.place_dynamic("2:1", :p)
          early.place_dynamic("2:3", :f)
        end
      end
      let(:rendered) { described_class.new(flow).to_s }

      it "writes them on the voice's whole-bar rest" do
        expect(bar_check_lines(rendered).first(2)).to eq ["e''1 |", %(\\after 2 \\f R1*4/4\\p \\bar "|." |)]
      end

      it "is structurally valid" do
        expect_structurally_valid_lilypond(rendered, bars: 2, voices: 2)
      end

      it "compiles without warnings" do
        skip "lilypond is not installed" unless installed_lilypond

        expect(compile_warnings(rendered)).to be_empty
      end
    end

    context "with levels in a voice that rests through a pickup and a short final bar" do
      let(:flow) do
        LilyPondFixtures.pickup_and_short_final_bar.tap do |flow|
          flow.voices.last.place_dynamic("1:1", :mf)
          flow.voices.last.place_dynamic("2:2", :p)
        end
      end
      let(:rendered) { described_class.new(flow).to_s }

      it "writes them on the rests that fill its bars" do
        expect(rendered.lines.map(&:strip).each_cons(3)).to include ["R1*3/4\\mf |", "\\after 4 \\p r2 \\bar \"|.\"", "}"]
      end

      it "compiles without warnings" do
        skip "lilypond is not installed" unless installed_lilypond

        expect(compile_warnings(rendered)).to be_empty
      end
    end

    context "with an empty voice" do
      let(:flow) { LilyPondFixtures.tacet }
      let(:rendered) { described_class.new(flow).to_s }

      it "renders a staff of whole-bar rests without raising" do
        expect(bar_check_lines(rendered)).to eq [%(R1*4/4 \\bar "|." |)]
      end

      it "defaults the empty voice to the treble clef" do
        expect(rendered).to include "\\clef treble"
      end

      it_behaves_like "a compilable document"
    end

    context "with sung voice events" do
      let(:flow) { LilyPondFixtures.song }
      let(:rendered) { described_class.new(flow).to_s }

      it "drops the lyrics and renders the music" do
        expect(rendered).not_to include "shenandoah"
      end

      it "does not raise" do
        expect { rendered }.not_to raise_error
      end
    end

    context "with quotes and backslashes in header fields" do
      let(:flow) { LilyPondFixtures.escaped_header }
      let(:rendered) { described_class.new(flow).to_s }

      it "escapes the title" do
        expect(rendered).to include %(title = "The \\"Great\\" \\\\ Escape")
      end

      it "escapes the composer" do
        expect(rendered).to include %(composer = "A. \\"Slash\\" Author")
      end
    end

    context "with a voice without a role" do
      let(:flow) { LilyPondFixtures.anonymous }

      it "omits the instrumentName block" do
        expect(described_class.new(flow).to_s).not_to include "instrumentName"
      end
    end

    context "with the golden example" do
      let(:flow) { LilyPondFixtures.air }
      let(:rendered) { described_class.new(flow).to_s }
      let(:expected_document) { LilyPondFixtures::AIR_DOCUMENT }

      it "renders the exact document" do
        expect(rendered).to eq expected_document
      end

      it_behaves_like "a compilable document"
    end

    context "with no voices" do
      let(:flow) { HeadMusic::Content::Flow.new }

      it "raises a render error before any assembly" do
        expect { described_class.new(flow).to_s }
          .to raise_error(HeadMusic::Notation::LilyPond::RenderError, /no voices/)
      end
    end

    context "with articulations, ornaments, and dynamics" do
      let(:flow) { MarkingFixtures.marked_melody }
      let(:rendered) { described_class.new(flow).to_s }

      it "is structurally valid" do
        expect_structurally_valid_lilypond(rendered, bars: 6, voices: 1)
      end

      it "writes the level, then the articulations, ornaments, and sforzando after each note" do
        expect(bar_check_lines(rendered).values_at(0, 1, 4)).to eq [
          "c''4\\p-. d''4-. e''4-. f''4-. |", "g''2\\trill a''2\\sfz |", "e''2\\f->\\mordent d''4-!\\prall c''4-^\\turn |"
        ]
      end

      it "writes a level under a held note with \\after, leaving the note whole" do
        expect(bar_check_lines(rendered).values_at(2, 3)).to eq ["\\after 2 \\mf g''1 |", "e''4-- f''2.\\fp |"]
      end

      it "writes a level on a rest" do
        expect(bar_check_lines(rendered).last).to eq %(c''2 r2\\pp \\bar "|." |)
      end

      it_behaves_like "a compilable document"
    end

    context "with a marked note split at a barline" do
      let(:flow) do
        HeadMusic::Content::Flow.new(name: "Split").tap do |flow|
          voice = flow.add_voice
          voice.place("1:1", :half, "C4")
          voice.place("1:3", :whole, "D4").articulate(:accent).embellish(:trill).note_dynamic = :sf
          voice.place("2:3", :half, "E4")
          voice.place_dynamic("1:3", :mp)
        end
      end
      let(:rendered) { described_class.new(flow).to_s }

      it "marks only the fragment where the note starts" do
        expect(bar_check_lines(rendered)).to eq ["c'2 d'2\\mp->\\trill\\sf~ |", %(d'2 e'2 \\bar "|." |)]
      end

      it_behaves_like "a compilable document"
    end

    # The fp puts p in force at its note over the level, so the level is left
    # out: the level in force reads back the same, though the event does not.
    context "with a level on a note that carries fp" do
      let(:flow) do
        HeadMusic::Content::Flow.new(name: "Forte-piano").tap do |flow|
          voice = flow.add_voice
          voice.place("1:1", :half, "C4").note_dynamic = :fp
          voice.place("1:3", :half, "D4")
          voice.place_dynamic("1:1", :f)
        end
      end
      let(:rendered) { described_class.new(flow).to_s }

      it "writes the fp and leaves out the level" do
        expect(bar_check_lines(rendered)).to eq [%(c'2\\fp d'2 \\bar "|." |)]
      end

      it "reads back the same level in force at every note, without the level's event" do
        restored = HeadMusic::Notation::LilyPond.parse(rendered).voices.first
        expect(%w[1:1 1:3].map { |position| restored.dynamic_at(position).name_key }).to eq %w[p p]
        expect(restored.dynamic_events).to be_empty
      end
    end

    context "with a marked chord" do
      let(:flow) do
        HeadMusic::Content::Flow.new(name: "Chord").tap do |flow|
          flow.add_voice.place("1:1", :whole, %w[C4 E4 G4]).articulate(:tenuto).note_dynamic = :rfz
        end
      end

      it "writes the marks once, after the chord" do
        expect(bar_check_lines(described_class.new(flow).to_s)).to eq [%(<c' e' g'>1--\\rfz \\bar "|." |)]
      end
    end

    context "with part dynamics on a grand staff" do
      let(:flow) { MarkingFixtures.grand_staff_piano_with_dynamics }
      let(:rendered) { described_class.new(flow).to_s }
      let(:dynamics_between_staves) do
        <<~LILYPOND.gsub(/^/, " " * 6)
          >>
          \\new Dynamics {
            s1\\p |
            s2 s2\\f |
            s1 |
            s1\\mp |
          }
          \\new Staff = "part1-staff2" <<
        LILYPOND
      end

      it "is structurally valid, with the Dynamics context as a stream of its own" do
        expect_structurally_valid_lilypond(rendered, bars: 4, voices: 2, streams: 3)
      end

      it "writes the part's levels between the staves at their exact positions" do
        expect(rendered).to include dynamics_between_staves
      end

      it "writes the voice's own level on its note" do
        expect(bar_check_lines(rendered)[2]).to eq "e''1\\mf |"
      end

      it_behaves_like "a compilable document"
    end

    context "with part dynamics beside a single staff" do
      let(:flow) { LilyPondFixtures.melody_with_part_dynamics }
      let(:rendered) { described_class.new(flow).to_s }

      it "is structurally valid across the change of meter" do
        expect_structurally_valid_lilypond(rendered, bars: 3, voices: 1, streams: 2)
      end

      it "writes the Dynamics context after the staff, reaching each level with spacers" do
        expect(rendered).to include("    }\n    \\new Dynamics {\n", "s2\\p s2\\mf |\n", "s2. s4\\f |\n", "s4 s2\\ff |\n")
      end

      it "writes the voice's own level at its position between the part's" do
        expect(bar_check_lines(rendered).first).to eq "\\after 4 \\pp g'1 |"
      end

      it_behaves_like "a compilable document"
    end

    context "with a part dynamic between the ticks of binary note values" do
      let(:flow) { LilyPondFixtures.anonymous.tap { |flow| flow.parts.first.place_dynamic("1:1:320", :f) } }

      it "raises a render error before any assembly" do
        expect { described_class.new(flow).to_s }
          .to raise_error(HeadMusic::Notation::LilyPond::RenderError, /cannot place the dynamic f at 1:1:320 in LilyPond output: no binary note value reaches it/)
      end
    end

    context "with a voice dynamic after the music between the ticks of binary note values" do
      let(:flow) do
        HeadMusic::Notation::ABC.parse("X:1\nT:Late\nL:1/4\nM:4/4\nK:C\nC D E|\n").tap do |flow|
          flow.voices.first.place_dynamic("1:4:320", :f)
        end
      end

      it "raises a render error before any assembly" do
        expect { described_class.new(flow).to_s }
          .to raise_error(HeadMusic::Notation::LilyPond::RenderError, /cannot place the dynamic f at 1:4:320 in LilyPond output/)
      end
    end

    context "with slurs and a phrasing slur" do
      let(:flow) { MarkingFixtures.spanned_melody }
      let(:rendered) { described_class.new(flow).to_s }

      it "is structurally valid" do
        expect_structurally_valid_lilypond(rendered, bars: 4, voices: 1)
      end

      it "opens a slur and a phrasing slur after their first note's marks" do
        expect(rendered).to include "c'4(\\( d'4 e'4) f'4 |"
      end

      it "closes a slur after the last link of a note tied across a barline" do
        expect(rendered).to include "c''4~ |\n", "c''4) d''4"
      end

      it "names a slur nested in another" do
        expect(rendered).to include "g'4( a'4\\=1( b'4\\=1)"
      end

      it "closes a phrasing slur on a rest" do
        expect(rendered).to include "r2\\)"
      end
    end

    context "with slurs that cross" do
      let(:flow) { MarkingFixtures.crossing_spans }

      it "names the second" do
        expect(described_class.new(flow).to_s).to include "c'4( d'4\\=1( e'4) f'4\\=1) |"
      end
    end

    context "with one slur ending where the next begins" do
      let(:flow) { MarkingFixtures.touching_slurs }

      it "closes the first before opening the second" do
        expect(described_class.new(flow).to_s).to include "e'4)( f'4"
      end
    end

    describe "voice hairpins" do
      def lines_of(fixture)
        bar_check_lines(described_class.new(HairpinFixtures.public_send(fixture)).to_s)
      end

      it "ends a hairpin on the later link of a tied note" do
        expect(lines_of(:hairpin_ending_on_tied_note)).to eq ["c'4\\< d'4 e'4 f'4~ |", %(f'4\\! g'4 a'4 b'4 \\bar "|." |)]
      end

      it "starts a hairpin on the later link of a tied note" do
        expect(lines_of(:hairpin_starting_on_split_note)).to eq ["c'4\\< d'4 e'4 f'4\\!~ |", %(f'4\\> g'4 a'4\\! b'4 \\bar "|." |)]
      end

      it "ends one hairpin before starting the next where they touch" do
        expect(lines_of(:touching_hairpins_on_tied_note).last).to eq %(f'4\\!\\> g'4 a'4 b'4\\! \\bar "|." |)
      end

      it "ends a hairpin on the later piece of a rest split at a barline" do
        expect(lines_of(:hairpin_on_split_rest)).to eq ["c'2\\< r2\\!\\> |", %(r2\\! d'2 \\bar "|." |)]
      end

      it "places ends inside held notes with \\after" do
        expect(lines_of(:hairpin_under_held_note)).to eq ["\\after 4 \\< c'1 |", %(\\after 4 \\! d'2 e'2 \\bar "|." |)]
      end

      it "places each voice's hairpins in its own voice" do
        expect(lines_of(:hairpins_in_two_voices).values_at(2, 3, 6))
          .to eq ["\\after 2 \\< e''1 |", %(\\after 2 \\! e''1 \\bar "|." |), "\\after 4 \\! c1 |"]
      end

      it "cuts a hairpin at a level and an accent inside it, ending before the level or accent and starting after" do
        expect(lines_of(:level_inside_hairpin)).to eq ["c'4\\< d'4 e'4\\!\\mf\\< f'4\\!\\sf\\< |", %(g'1\\! \\bar "|." |)]
      end

      {
        hairpin_on_split_rest: [2, 1], level_inside_hairpin: [2, 1], hairpins_in_two_voices: [4, 2],
        hairpin_to_music_end: [2, 1], hairpins_after_short_final_bar: [2, 1], hairpin_in_voice_that_ends_early: [2, 2]
      }.each do |fixture, (bars, voices)|
        it "writes #{fixture.to_s.tr("_", " ")} as structurally valid LilyPond" do
          expect_structurally_valid_lilypond(described_class.new(HairpinFixtures.public_send(fixture)).to_s, bars: bars, voices: voices)
        end
      end

      it "ends a hairpin on the final barline with a marker after the last note" do
        expect(lines_of(:hairpin_to_music_end).last).to eq %(d'1\\< <>\\! \\bar "|." |)
      end

      it "starts a hairpin after a short final bar's music on a spacer, ending it on the final barline" do
        expect(lines_of(:hairpins_after_short_final_bar).last).to eq %(c'4\\< d'4 e'4 s4\\!\\> <>\\! \\bar "|." |)
      end

      it "places a hairpin under a pickup's leading rest" do
        expect(lines_of(:hairpin_in_pickup).first).to eq "\\after 4 \\< r2 c'2 |"
      end

      it "places a hairpin's end and a level in a bar of whole-bar rest" do
        expect(lines_of(:hairpin_in_voice_that_ends_early)[1]).to eq %(\\after 4 \\! \\after 2 \\f R1*4/4 \\bar "|." |)
      end

      context "when a hairpin ends on the final barline after a short final bar" do
        let(:flow) do
          HeadMusic::Notation::ABC.parse("X:1\nT:Short\nL:1/4\nM:4/4\nK:C\nC4|C D E|\n").tap do |flow|
            flow.voices.first.add_span(:crescendo, from: "2:1", to: "3:1")
          end
        end

        it "leaves the bar short, ending the hairpin after the last note" do
          expect(bar_check_lines(described_class.new(flow).to_s).last).to eq "c'1 |"
          expect(described_class.new(flow).to_s).to include %(c'4\\< d'4 e'4 <>\\! \\bar "|.")
        end
      end

      context "when a hairpin ends where a short final bar's music ends" do
        let(:flow) do
          HeadMusic::Notation::ABC.parse("X:1\nT:Short\nL:1/4\nM:4/4\nK:C\nC4|C D E|\n").tap do |flow|
            flow.voices.first.add_span(:crescendo, from: "2:1", to: "2:4")
          end
        end

        it "fills the bar with a spacer that ends it" do
          expect(bar_check_lines(described_class.new(flow).to_s).last).to eq %(c'4\\< d'4 e'4 s4\\! \\bar "|." |)
        end
      end
    end

    describe "part hairpins" do
      it "writes a part with hairpins and no levels a Dynamics context, ending on the final barline after the last spacer" do
        expect(described_class.new(HairpinFixtures.single_voice_part_hairpin).to_s)
          .to include "\\new Dynamics {\n      s2\\< s2\\!\\> |\n      s1 <>\\! |\n    }"
      end

      it "writes the part's hairpins between the staves, apart from the voice's" do
        rendered = described_class.new(HairpinFixtures.part_hairpin).to_s
        expect(rendered).to include "\\new Dynamics {\n", "  s1\\< |\n", "  s2 s2\\! |\n", "  s1\\> |\n", "  s1 <>\\! |\n"
      end

      it "is structurally valid" do
        expect_structurally_valid_lilypond(described_class.new(HairpinFixtures.part_hairpin).to_s, bars: 4, voices: 2, streams: 3)
      end

      context "with a level inside a part hairpin" do
        let(:flow) do
          HairpinFixtures.abc("Part Level", "C D E F|G4|").tap do |flow|
            flow.parts.first.add_span(:crescendo, from: "1:1", to: "2:1")
            flow.parts.first.place_dynamic("1:2", :p)
            flow.voices.first.place_dynamic("1:3", :f)
          end
        end
        let(:rendered) { described_class.new(flow).to_s }

        it "cuts the hairpin at the part's level but not the voice's" do
          expect(rendered).to include "  s4\\< s2.\\!\\p\\< |\n", "  s1\\! |\n"
          expect(bar_check_lines(rendered).first).to eq "c'4 d'4 e'4\\f f'4 |"
        end

        it "compiles without warnings, drawing both pieces" do
          skip "lilypond is not installed" unless installed_lilypond

          expect(compile_hairpins(rendered)).to eq(warnings: [], hairpins: 2)
        end
      end

      context "with a part hairpin after the music of a short final bar" do
        let(:flow) do
          HairpinFixtures.abc("Short Part", "C4|C D E|").tap do |flow|
            flow.parts.first.add_span(:diminuendo, from: "2:4", to: "3:1")
          end
        end
        let(:rendered) { described_class.new(flow).to_s }

        it "fills the final bar so the hairpin starts on a spacer" do
          expect(rendered).to include "  s2. s4\\> <>\\! |\n", %(c'4 d'4 e'4 s4 \\bar "|." |)
        end

        it "compiles without warnings, drawing the hairpin" do
          skip "lilypond is not installed" unless installed_lilypond

          expect(compile_hairpins(rendered)).to eq(warnings: [], hairpins: 1)
        end
      end

      context "with a part hairpin ending on the final barline after a short final bar" do
        let(:flow) do
          HairpinFixtures.abc("Short Part", "C4|C D E|").tap do |flow|
            flow.parts.first.add_span(:crescendo, from: "2:1", to: "3:1")
          end
        end

        it "leaves the bar short, ending the hairpin after the last spacer" do
          expect(described_class.new(flow).to_s).to include "  s1 |\n      s2.\\< <>\\!\n"
        end
      end
    end

    describe "hairpin fixtures" do
      expected_hairpins = {
        hairpin_ending_on_tied_note: 1, hairpin_starting_on_split_note: 2, touching_hairpins_on_tied_note: 2,
        hairpin_on_split_rest: 2, hairpins_in_two_voices: 3, hairpin_under_held_note: 1,
        part_hairpin: 3, single_voice_part_hairpin: 2, hairpin_to_music_end: 1, hairpins_after_short_final_bar: 2, hairpin_in_pickup: 1,
        hairpin_in_voice_that_ends_early: 1, level_inside_hairpin: 3
      }

      expected_hairpins.each do |fixture, count|
        context "with #{fixture.to_s.tr("_", " ")}" do
          let(:rendered) { described_class.new(HairpinFixtures.public_send(fixture)).to_s }

          it "compiles without warnings, drawing #{count} hairpins" do
            skip "lilypond is not installed" unless installed_lilypond

            expect(compile_hairpins(rendered)).to eq(warnings: [], hairpins: count)
          end
        end
      end
    end

    describe "hairpin generator flows" do
      def expect_book_to_compile(seeds)
        book = seeds.map { |seed| HairpinGenerator.flow(seed) }
        count = book.sum { |flow| (flow.parts + flow.voices).sum { |owner| owner.spans.count(&:hairpin?) } }
        rendered = HeadMusic::Notation::LilyPond::BookWriter.new(book).to_s
        expect(compile_hairpins(rendered)).to eq(warnings: [], hairpins: count), "in the book of seeds #{seeds.first}..#{seeds.last}"
      end

      # A book of a hundred at a time, since a far longer one warns that
      # LilyPond compressed a page.
      it "compile in books without warnings, drawing every part's and voice's hairpins" do
        skip "lilypond is not installed" unless installed_lilypond

        HairpinGenerator::SEEDS.each_slice(100) { |seeds| expect_book_to_compile(seeds) }
      end
    end

    context "with a D.S. al Coda" do
      let(:flow) { LilyPondFixtures.dal_segno_al_coda }
      let(:rendered) { described_class.new(flow).to_s }
      let(:marked_lines) do
        [
          %(\\mark "A" c'4 d'4 e'4 f'4 |),
          %(\\segnoMark 1 g'4 a'4 b'4 c''4 |),
          %(\\mark "B" d''4 c''4 b'4 a'4 \\jump "To Coda" |),
          %(g'4 f'4 e'4 d'4 \\jump "D.S. al Coda" \\bar "||" |),
          %(\\codaMark 1 c'4 e'4 g'4 c''4 \\bar "|." |),
          %(\\mark "A" c1 |),
          %(\\segnoMark 1 c1 |),
          %(\\mark "B" c1 \\jump "To Coda" |),
          %(c1 \\jump "D.S. al Coda" \\bar "||" |),
          %(\\codaMark 1 c1 \\bar "|." |)
        ]
      end

      it "is structurally valid" do
        expect_structurally_valid_lilypond(rendered, bars: 5, voices: 2)
      end

      it "opens each bar with its marks and closes it with its navigation and barline, in every voice" do
        expect(bar_check_lines(rendered)).to eq marked_lines
      end

      it_behaves_like "a compilable document"
    end

    context "with every barline style and a Fine before the last bar" do
      let(:flow) { LilyPondFixtures.barline_styles }
      let(:rendered) { described_class.new(flow).to_s }
      let(:marked_lines) do
        [
          %(\\mark "Verse" e''1 \\textEndMark "Fine" \\bar "|." |),
          %(e''1 \\textEndMark "To Coda" \\jump "D.C." |),
          %(\\mark "Verse" c1 \\bar "|." |),
          %(c1 \\jump "D.C." |)
        ]
      end

      it "is structurally valid" do
        expect_structurally_valid_lilypond(rendered, bars: 5, voices: 2)
      end

      it "writes the text marks in the lead voice alone" do
        expect(bar_check_lines(rendered).values_at(0, 3, 5, 8)).to eq marked_lines
      end

      it_behaves_like "a compilable document"
    end

    context "with bar marks on a staff nobody is written on and beside part dynamics" do
      let(:flow) do
        LilyPondFixtures.one_handed_piano.tap do |flow|
          flow.parts.first.place_dynamic("1:1", :p)
          flow.bars.first.rehearsal_mark = "A"
          flow.bars.first.barline = :double
        end
      end
      let(:rendered) { described_class.new(flow).to_s }

      it "writes them in the voice alone" do
        expect(rendered.scan(%(\\mark "A")).length).to eq 1
        expect(rendered.scan(%(\\bar "||")).length).to eq 1
        expect(rendered.scan(%(\\bar "|.")).length).to eq 1
      end

      it_behaves_like "a compilable document"
    end

    describe "tuplets and grace notes" do
      def rendered_lines(flow)
        bar_check_lines(described_class.new(flow).to_s)
      end

      TupletFixtures.all.each do |fixture|
        context "with the #{fixture.to_s.tr("_", " ")} fixture" do
          let(:flow) { TupletFixtures.public_send(fixture) }
          let(:rendered) { described_class.new(flow).to_s }

          it "is structurally valid, its bars full under their brackets" do
            bars = HeadMusic::Notation::LilyPond::RenderPlan.new(flow).bar_numbers.count
            expect_structurally_valid_lilypond(rendered, bars: bars, voices: flow.voices.length)
          end

          it_behaves_like "a document that compiles without warnings"
        end
      end

      it "brackets each group with its ratio" do
        expect(rendered_lines(TupletFixtures.triplets).first)
          .to eq "\\tuplet 3/2 { c'8 d'8 e'8 } \\tuplet 3/2 { f'8 g'8 a'8 } \\tuplet 3/2 { b'4 c''4 d''4 } |"
      end

      it "writes a ratio as held, unreduced" do
        expect(rendered_lines(TupletFixtures.sextuplet).first).to eq "\\tuplet 6/4 { c'16 d'16 e'16 f'16 g'16 a'16 } g'2. |"
      end

      it "writes a duplet as a ratio below one" do
        expect(rendered_lines(TupletFixtures.duplet_in_six_eight).first).to eq "\\tuplet 2/3 { c'8 e'8 } g'4. |"
      end

      it "brackets a group of mixed values, rests, and chords" do
        expect(rendered_lines(TupletFixtures.mixed_value_tuplet).first).to eq "\\tuplet 3/2 { c'4 d'8 } \\tuplet 3/2 { r8 <e' g'>4 } f'2 |"
      end

      it "brackets an ungrouped run as a writer counts it" do
        expect(rendered_lines(TupletFixtures.ungrouped_tuplet_run).first).to eq "\\tuplet 3/2 { c'8 d'8 e'8 } \\tuplet 3/2 { f'8 g'8 a'8 } g'2 |"
      end

      it "closes a group partway through a chain, after the tie" do
        expect(rendered_lines(TupletFixtures.triplet_tied_out).first).to eq "\\tuplet 3/2 { c'8 d'8 e'8~ } e'4 f'2 |"
      end

      it "carries a group across a barline, the split note tied under the ratio" do
        expect(rendered_lines(TupletFixtures.tuplet_crossing_barline)).to eq ["c'2. \\tuplet 3/2 { d'4 e'8~ |", "e'8 f'4 } g'2. \\bar \"|.\" |"]
      end

      it "splits a rounded note at its exact barline" do
        expect(rendered_lines(TupletFixtures.septuplet_crossing_barline))
          .to eq ["c'2. \\tuplet 7/4 { d'8 e'8 f'8 g'16~ |", "g'16 a'8 b'8 c''8 } d''2. \\bar \"|.\" |"]
      end

      context "with voice marks at and inside tuplet notes" do
        let(:flow) do
          TupletFixtures.triplets.tap do |flow|
            voice = flow.voices.first
            voice.place_dynamic(voice.voice_events[1].position, :p)
            voice.place_dynamic("1:4", :f)
            voice.add_span(:crescendo, from: voice.voice_events[4].position, to: voice.voice_events[7].position)
          end
        end
        let(:rendered) { described_class.new(flow).to_s }

        it "writes a mark at a tuplet onset on its note, and one inside a note after the written time it reaches" do
          expect(bar_check_lines(rendered).first)
            .to eq "\\tuplet 3/2 { c'8 d'8\\p e'8 } \\tuplet 3/2 { f'8 g'8\\< a'8 } \\tuplet 3/2 { b'4 \\after 8 \\f c''4\\! d''4 } |"
        end

        it_behaves_like "a document that compiles without warnings"
      end

      context "with part levels at the onsets of rounded notes" do
        let(:flow) do
          TupletFixtures.septuplet.tap do |flow|
            onsets = flow.voices.first.voice_events.map(&:position)
            flow.parts.first.place_dynamic(onsets[1], :mf)
            flow.parts.first.place_dynamic(onsets[4], :p)
          end
        end
        let(:rendered) { described_class.new(flow).to_s }

        it "reaches each exact onset with multiplied spacers" do
          expect(rendered).to include "s1*1/28 s1*3/28\\mf s1*6/7\\p |"
        end

        it "is structurally valid" do
          expect_structurally_valid_lilypond(rendered, bars: 2, voices: 1, streams: 2)
        end

        it_behaves_like "a document that compiles without warnings"
      end

      context "with a short final bar no note value rests through" do
        let(:flow) do
          HeadMusic::Content::Flow.new(name: "Short").tap do |flow|
            flow.add_voice.place("1:1", HeadMusic::Rudiment::RhythmicValue.get(:eighth, tuplet: "3:2"), "C4")
            flow.add_part(instrument: "oboe")
          end
        end

        it "raises a render error naming the bar" do
          expect { described_class.new(flow).to_s }
            .to raise_error(HeadMusic::Notation::LilyPond::RenderError, /cannot rest through the short final bar 1/)
        end
      end

      describe "generator flows" do
        def expect_book_to_compile(seeds)
          book = seeds.map { |seed| TupletGenerator.flow(seed, voices: 2, pickup: true) }
          rendered = on_one_page(HeadMusic::Notation::LilyPond::BookWriter.new(book).to_s)
          expect(compile_warnings(rendered)).to eq([]), "in the book of seeds #{seeds.first}..#{seeds.last}"
        end

        it "compile in books without warnings" do
          skip "lilypond is not installed" unless installed_lilypond

          TupletGenerator::SEEDS.each_slice(100) { |seeds| expect_book_to_compile(seeds) }
        end

        it "are structurally valid" do
          TupletGenerator::SEEDS.each do |seed|
            flow = TupletGenerator.flow(seed, voices: 2, pickup: true)
            bars = HeadMusic::Notation::LilyPond::RenderPlan.new(flow).bar_numbers.count
            expect_structurally_valid_lilypond(described_class.new(flow).to_s, bars: bars, voices: 2)
          end
        end
      end

      describe "grace notes" do
        def four_quarters
          HeadMusic::Content::Flow.new(name: "Graced").tap do |flow|
            voice = flow.add_voice
            %w[C4 E4 G4 F4].each { |pitch| voice.place(voice.next_position, :quarter, pitch) }
            voice.place(voice.next_position, :whole, "E4")
          end
        end

        it "writes slashed grace notes with \\slashedGrace and others with \\grace, with their chords and articulations" do
          expect(rendered_lines(TupletFixtures.grace_notes_before_downbeat).first(2))
            .to eq ["c'4 e'4 \\grace <a' c''>16 g'4 \\grace g'16-. f'4 |", "\\slashedGrace f'8 e'1 |"]
        end

        it "writes grace notes slurred to their main note with \\appoggiatura, braced and tied in" do
          expect(rendered_lines(TupletFixtures.grace_notes_before_downbeat).last).to eq "\\appoggiatura { d'16 c'16~ } c'1 \\bar \"|.\" |"
        end

        it "writes grace notes in a pickup" do
          expect(rendered_lines(TupletFixtures.grace_notes_in_pickup).first).to eq "r2 \\grace a8 g4 b4 |"
        end

        context "with slurs from grace notes to their main note and to a later one" do
          let(:flow) do
            four_quarters.tap do |flow|
              voice = flow.voices.first
              voice.voice_events[1].add_grace_note("F4", :eighth, slashed: true)
              voice.add_span(:slur, from: "1:2", to: "1:2", from_grace: true)
              voice.voice_events[2].add_grace_note("A4", :eighth, slashed: true)
              voice.add_span(:slur, from: "1:3", to: "1:4", from_grace: true)
            end
          end
          let(:rendered) { described_class.new(flow).to_s }

          it "writes \\acciaccatura for the one to the main note, and opens the later one on the grace note" do
            expect(bar_check_lines(rendered).first).to eq "c'4 \\acciaccatura f'8 e'4 \\slashedGrace a'8( g'4 f'4) |"
          end

          it "is structurally valid" do
            expect_structurally_valid_lilypond(rendered, bars: 2, voices: 1)
          end

          it_behaves_like "a document that compiles without warnings"
        end

        context "with slurs from grace notes inside another slur, and from grace notes of both slashes" do
          let(:flow) do
            four_quarters.tap do |flow|
              voice = flow.voices.first
              voice.add_span(:slur, from: "1:1", to: "1:4")
              voice.voice_events[1].add_grace_note("D4", :sixteenth)
              voice.add_span(:slur, from: "1:2", to: "1:2", from_grace: true)
              voice.voice_events[3].add_grace_note("A4", :sixteenth, slashed: true).add_grace_note("B4", :sixteenth)
              voice.add_span(:slur, from: "1:4", to: "1:4", from_grace: true)
            end
          end
          let(:rendered) { described_class.new(flow).to_s }

          it "names each, since the other is open across its grace notes, and writes a command for each slash" do
            expect(bar_check_lines(rendered).first)
              .to eq "c'4( \\grace d'16\\=1( e'4\\=1) g'4 \\slashedGrace a'16\\=1( \\grace b'16 f'4)\\=1) |"
          end

          it_behaves_like "a document that compiles without warnings"
        end

        context "with a phrasing slur from a grace note" do
          let(:flow) do
            four_quarters.tap do |flow|
              flow.voices.first.voice_events[3].add_grace_note("D4", :sixteenth)
              flow.voices.first.add_span(:phrase, from: "1:4", to: "2:1", from_grace: true)
            end
          end
          let(:rendered) { described_class.new(flow).to_s }

          it "opens it on the grace note, since no command implies one" do
            expect(bar_check_lines(rendered)).to eq ["c'4 e'4 g'4 \\grace d'16\\( f'4 |", "e'1\\) \\bar \"|.\" |"]
          end

          it_behaves_like "a document that compiles without warnings"
        end

        context "with grace notes on a tuplet's first note, a level inside it" do
          let(:flow) do
            TupletFixtures.triplets.tap do |flow|
              voice = flow.voices.first
              main = voice.voice_events[6]
              main.add_grace_note("A4", :eighth, slashed: true)
              voice.add_span(:slur, from: main.position, to: main.position, from_grace: true)
              voice.place_dynamic("1:3:480", :p)
            end
          end
          let(:rendered) { described_class.new(flow).to_s }

          it "writes the bracket, the grace notes, the \\after, then the note" do
            expect(bar_check_lines(rendered).first).to end_with "\\tuplet 3/2 { \\acciaccatura a'8 \\after 8. \\p b'4 c''4 d''4 } |"
          end

          it_behaves_like "a document that compiles without warnings"
        end

        context "with grace notes before a note split at a barline" do
          let(:flow) do
            HeadMusic::Content::Flow.new(name: "Split").tap do |flow|
              voice = flow.add_voice
              voice.place("1:1", :dotted_half, "C4")
              voice.place("1:4", :half, "D4").add_grace_note("E4", :sixteenth)
              voice.place("2:2", :dotted_half, "C4")
            end
          end
          let(:rendered) { described_class.new(flow).to_s }

          it "writes them before its first piece alone" do
            expect(bar_check_lines(rendered)).to eq ["c'2. \\grace e'16 d'4~ |", "d'4 c'2. \\bar \"|.\" |"]
          end

          it_behaves_like "a document that compiles without warnings"
        end
      end
    end
  end
end
