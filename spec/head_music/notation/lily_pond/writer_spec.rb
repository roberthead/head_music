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
        expect(bar_check_lines(rendered)).to eq ["c'4 r4 e'2 |"]
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
        expect(bar_check_lines(rendered).last).to eq "R1*4/4 |"
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
        expect(bar_check_lines(rendered).first(2)).to eq ["c''2 d''2~ |", "\\key g \\major d''2 fis''2 |"]
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
        expect(rendered.lines.map(&:strip).grep(/\A(r2 |c'?'?2\.|b'2|g2)/)).to eq ["r2 g'4 |", "c''2. |", "b'2", "r2 g4 |", "c2. |", "g2"]
      end

      it_behaves_like "a compilable document"
    end

    context "with a pickup, a short final bar, and a tacet voice" do
      let(:flow) { LilyPondFixtures.pickup_and_short_final_bar }
      let(:rendered) { described_class.new(flow).to_s }

      it "rests the tacet voice only as long as the short final bar" do
        expect(rendered.lines.map(&:strip).each_cons(3)).to include ["R1*3/4 |", "R1*3/4 |", "r2"]
      end

      it_behaves_like "a compilable document"
    end

    context "with an empty voice" do
      let(:flow) { LilyPondFixtures.tacet }
      let(:rendered) { described_class.new(flow).to_s }

      it "renders a staff of whole-bar rests without raising" do
        expect(bar_check_lines(rendered)).to eq ["R1*4/4 |"]
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

      it "moves a level under a held note to the next note" do
        expect(bar_check_lines(rendered).values_at(2, 3)).to eq ["g''1 |", "e''4\\mf-- f''2.\\fp |"]
      end

      it "writes a level on a rest" do
        expect(bar_check_lines(rendered).last).to eq "c''2 r2\\pp |"
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
          voice.place_dynamic("3:1", :ff)
        end
      end
      let(:rendered) { described_class.new(flow).to_s }

      it "marks only the fragment where the note starts" do
        expect(bar_check_lines(rendered)).to eq ["c'2 d'2\\mp->\\trill\\sf~ |", "d'2 e'2 |"]
      end

      it "leaves out a level with no note after it" do
        expect(rendered).not_to include "\\ff"
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
        expect(bar_check_lines(rendered)).to eq ["c'2\\fp d'2 |"]
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
        expect(bar_check_lines(described_class.new(flow).to_s)).to eq ["<c' e' g'>1--\\rfz |"]
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

      it "leaves out the voice's level where the part's has overtaken it" do
        expect(rendered).not_to include "\\pp"
      end

      it_behaves_like "a compilable document"
    end

    context "with a part dynamic between the ticks of binary note values" do
      let(:flow) { LilyPondFixtures.anonymous.tap { |flow| flow.parts.first.place_dynamic("1:1:320", :f) } }

      it "raises a render error before any assembly" do
        expect { described_class.new(flow).to_s }
          .to raise_error(HeadMusic::Notation::LilyPond::RenderError, /part's dynamics in bar 1/)
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
  end
end
