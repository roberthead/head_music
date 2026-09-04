require "spec_helper"

describe HeadMusic::Notation::LilyPond::Writer do
  describe "#to_s" do
    context "with a single-voice diatonic tune" do
      let(:composition) { LilyPondFixtures.speed_the_plough }
      let(:rendered) { described_class.new(composition).to_s }

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
      let(:composition) { LilyPondFixtures.chromatic_air }
      let(:rendered) { described_class.new(composition).to_s }

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
      let(:composition) { LilyPondFixtures.rests }
      let(:rendered) { described_class.new(composition).to_s }

      it "is structurally valid" do
        expect_structurally_valid_lilypond(rendered, bars: 1, voices: 1)
      end

      it "renders the rest between the notes" do
        expect(bar_check_lines(rendered)).to eq ["c'4 r4 e'2 |"]
      end
    end

    context "with multiple voices" do
      let(:composition) { LilyPondFixtures.duo }
      let(:rendered) { described_class.new(composition).to_s }

      it "is structurally valid" do
        expect_structurally_valid_lilypond(rendered, bars: 2, voices: 2)
      end

      it "emits one staff per voice, in composition order" do
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

    context "with a mid-piece key and meter change" do
      let(:composition) { LilyPondFixtures.key_and_meter_change }
      let(:rendered) { described_class.new(composition).to_s }

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
      let(:composition) { LilyPondFixtures.tacet }
      let(:rendered) { described_class.new(composition).to_s }

      it "renders a staff of whole-bar rests without raising" do
        expect(bar_check_lines(rendered)).to eq ["R1*4/4 |"]
      end

      it "defaults the empty voice to the treble clef" do
        expect(rendered).to include "\\clef treble"
      end

      it_behaves_like "a compilable document"
    end

    context "with sung placements" do
      let(:composition) { LilyPondFixtures.song }
      let(:rendered) { described_class.new(composition).to_s }

      it "drops the lyrics and renders the music" do
        expect(rendered).not_to include "shenandoah"
      end

      it "does not raise" do
        expect { rendered }.not_to raise_error
      end
    end

    context "with quotes and backslashes in header fields" do
      let(:composition) { LilyPondFixtures.escaped_header }
      let(:rendered) { described_class.new(composition).to_s }

      it "escapes the title" do
        expect(rendered).to include %(title = "The \\"Great\\" \\\\ Escape")
      end

      it "escapes the composer" do
        expect(rendered).to include %(composer = "A. \\"Slash\\" Author")
      end
    end

    context "with a voice without a role" do
      let(:composition) { LilyPondFixtures.anonymous }

      it "omits the instrumentName block" do
        expect(described_class.new(composition).to_s).not_to include "instrumentName"
      end
    end

    context "with the golden example" do
      let(:composition) { LilyPondFixtures.air }
      let(:rendered) { described_class.new(composition).to_s }
      let(:expected_document) { LilyPondFixtures::AIR_DOCUMENT }

      it "renders the exact document" do
        expect(rendered).to eq expected_document
      end

      it_behaves_like "a compilable document"
    end

    context "with no voices" do
      let(:composition) { HeadMusic::Content::Composition.new }

      it "raises a render error before any assembly" do
        expect { described_class.new(composition).to_s }
          .to raise_error(HeadMusic::Notation::LilyPond::RenderError, /no voices/)
      end
    end
  end
end
