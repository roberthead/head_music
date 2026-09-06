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

    context "with sung placements" do
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
  end
end
