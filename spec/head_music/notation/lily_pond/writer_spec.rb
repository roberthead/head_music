require "spec_helper"
require "tmpdir"

describe HeadMusic::Notation::LilyPond::Writer do
  def installed_lilypond
    ENV["PATH"].split(File::PATH_SEPARATOR)
      .map { |dir| File.join(dir, "lilypond") }
      .find { |path| File.executable?(path) }
  end

  def compile_quietly(lilypond, source)
    Dir.mktmpdir do |dir|
      source_path = File.join(dir, "golden.ly")
      File.write(source_path, source)
      system(lilypond, "--output", dir, source_path, out: File::NULL, err: File::NULL)
    end
  end

  shared_examples "a compilable document" do
    it "compiles with the lilypond binary when one is installed" do
      lilypond = installed_lilypond
      skip "lilypond is not installed" unless lilypond

      expect(compile_quietly(lilypond, rendered)).to be true
    end
  end

  describe "#to_s" do
    context "with a single-voice diatonic tune" do
      let(:composition) { HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH) }
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
      let(:composition) { HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR) }
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
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(name: "Rests")
        voice = composition.add_voice
        voice.place("1:1", :quarter, "C4")
        voice.place("1:2", :quarter)
        voice.place("1:3", :half, "E4")
        composition
      end
      let(:rendered) { described_class.new(composition).to_s }

      it "is structurally valid" do
        expect_structurally_valid_lilypond(rendered, bars: 1, voices: 1)
      end

      it "renders the rest between the notes" do
        expect(bar_check_lines(rendered)).to eq ["c'4 r4 e'2 |"]
      end
    end

    context "with multiple voices" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(name: "Duo", key_signature: "C major", meter: "4/4")
        upper = composition.add_voice(role: "Melody")
        upper.place("1:1", :whole, "E5")
        upper.place("2:1", :whole, "D5")
        lower = composition.add_voice(role: "Bass line")
        lower.place("1:1", :whole, "C3")
        composition
      end
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
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(name: "Turn", key_signature: "G major", meter: "4/4")
        %w[G4 G3].each do |pitch|
          voice = composition.add_voice
          voice.place("1:1", :whole, pitch)
          voice.place("2:1", :whole, pitch)
          voice.place("3:1", "dotted half", pitch)
        end
        composition.change_key_signature(3, "D major")
        composition.change_meter(3, "3/4")
        composition
      end
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
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(name: "Tacet")
        composition.add_voice
        composition
      end
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
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(name: "Song")
        composition.add_voice.place("1:1", :whole, "C4").sing("shenandoah")
        composition
      end
      let(:rendered) { described_class.new(composition).to_s }

      it "drops the lyrics and renders the music" do
        expect(rendered).not_to include "shenandoah"
      end

      it "does not raise" do
        expect { rendered }.not_to raise_error
      end
    end

    context "with quotes and backslashes in header fields" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(
          name: %(The "Great" \\ Escape), composer: %(A. "Slash" Author)
        )
        composition.add_voice.place("1:1", :whole, "C4")
        composition
      end
      let(:rendered) { described_class.new(composition).to_s }

      it "escapes the title" do
        expect(rendered).to include %(title = "The \\"Great\\" \\\\ Escape")
      end

      it "escapes the composer" do
        expect(rendered).to include %(composer = "A. \\"Slash\\" Author")
      end
    end

    context "with a voice without a role" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(name: "Anon")
        composition.add_voice.place("1:1", :whole, "C4")
        composition
      end

      it "omits the instrumentName block" do
        expect(described_class.new(composition).to_s).not_to include "instrumentName"
      end
    end

    context "with the golden example" do
      let(:composition) do
        composition = HeadMusic::Content::Composition.new(
          name: "Air", key_signature: "G major", meter: "4/4", composer: "Aloysius"
        )
        voice = composition.add_voice(role: "Melody")
        voice.place("1:1", :quarter, "G4")
        voice.place("1:2", :quarter, "A4")
        voice.place("1:3", :quarter, "B4")
        voice.place("1:4", :quarter, "C5")
        voice.place("2:1", :half, "D5")
        voice.place("2:3", :half, "G4")
        composition
      end
      let(:rendered) { described_class.new(composition).to_s }
      let(:expected_document) do
        <<~LILYPOND
          \\version "2.24.0"
          \\header {
            title = "Air"
            composer = "Aloysius"
          }
          \\score {
            <<
              \\new Staff \\with { instrumentName = "Melody" } {
                \\new Voice {
                  \\clef treble
                  \\key g \\major
                  \\time 4/4
                  g'4 a'4 b'4 c''4 |
                  d''2 g'2 |
                }
              }
            >>
            \\layout { }
          }
        LILYPOND
      end

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
