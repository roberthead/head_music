require "spec_helper"

describe HeadMusic::Notation::LilyPond::Parser do
  def parse(source)
    HeadMusic::Notation::LilyPond.parse(source)
  end

  # The exceptions outside the ParseError family raised by parsing every
  # single-character deletion of the source.
  def escaped_errors(source)
    source.length.times.filter_map do |index|
      mutated = source.dup
      mutated.slice!(index)
      parse(mutated)
      nil
    rescue HeadMusic::Notation::ParseError
      nil
    rescue => error
      [mutated, error]
    end
  end

  describe "input validation" do
    it "raises for nil input" do
      expect { parse(nil) }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /blank/)
    end

    it "raises for empty input" do
      expect { parse("") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /blank/)
    end

    it "raises for whitespace-only input" do
      expect { parse(" \n\t\n") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /blank/)
    end

    it "raises for a comment-only document" do
      expect { parse("% nothing\n%{ nothing %}") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /no music/)
    end

    it "raises for an empty expression" do
      expect { parse("{ }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /no music/)
    end

    # File.read tags its result UTF-8 whatever the bytes are, so a Latin-1
    # file reaches the parser as a UTF-8 string with invalid bytes.
    it "raises a parse error for a UTF-8 string holding invalid bytes" do
      source = "{ c'1 } % caf\xE9".dup.force_encoding(Encoding::UTF_8)
      expect { parse(source) }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /not valid UTF-8/)
    end

    it "raises a parse error for braces nested beyond the reader's depth" do
      source = ("{ " * 2000) + "c'1" + (" }" * 2000)
      expect { parse(source) }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /nested too deeply/)
    end
  end

  describe "#composition" do
    it "does not memoize a failure" do
      parser = described_class.new("{ c'1 d'4 | }")
      expect { parser.composition }.to raise_error(HeadMusic::Notation::LilyPond::ParseError)
      expect { parser.composition }.to raise_error(HeadMusic::Notation::LilyPond::ParseError)
    end
  end

  describe "the story's example" do
    subject(:composition) do
      parse(<<~LILY)
        \\relative c' {
          \\key g \\major
          \\time 4/4
          g8 a b c d c b g
        }
      LILY
    end

    let(:voice) { composition.voices.first }

    it "returns a composition" do
      expect(composition).to be_a HeadMusic::Content::Composition
    end

    it "maps the key" do
      expect(composition.key_signature).to eq HeadMusic::Rudiment::KeySignature.get("G major")
    end

    it "maps the meter" do
      expect(composition.meter.to_s).to eq "4/4"
    end

    it "produces one voice" do
      expect(composition.voices.length).to eq 1
    end

    it "resolves the relative pitches" do
      expect(voice.pitches.map(&:to_s)).to eq %w[G3 A3 B3 C4 D4 C4 B3 G3]
    end

    it "carries the eighth duration through the bar" do
      expect(voice.placements.map { |placement| placement.rhythmic_value.to_s }.uniq).to eq ["eighth"]
    end

    it "fills exactly one bar" do
      expect(voice.next_position.to_s).to eq "2:1:000"
    end
  end

  describe "a full document" do
    subject(:composition) { parse(LilyPondFixtures::AIR_DOCUMENT) }

    it "maps the header" do
      expect([composition.name, composition.composer]).to eq ["Air", "Aloysius"]
    end

    it "maps the instrument name to the voice role" do
      expect(composition.voices.map(&:role)).to eq ["Melody"]
    end

    it "reads the absolute pitches" do
      expect(composition.voices.first.pitches.map(&:to_s)).to eq %w[G4 A4 B4 C5 D5 G4]
    end

    it "is the composition the writer rendered" do
      expect(composition.to_lilypond).to eq LilyPondFixtures::AIR_DOCUMENT
    end
  end

  describe "comments and whitespace" do
    it "ignores comments of both kinds and irregular whitespace" do
      source = "{\t% opening\n\tc'4 %{ a\nblock %} d'4\n\n  e'2 | % done\n}"
      expect(parse(source).voices.first.pitches.map(&:to_s)).to eq %w[C4 D4 E4]
    end
  end

  describe "multiple voices" do
    it "produces one voice per staff" do
      source = "<< \\new Staff { c'1 } \\new Staff { e1 } \\new Staff { g,1 } >>"
      expect(parse(source).voices.map { |voice| voice.pitches.first.to_s }).to eq %w[C4 E3 G2]
    end
  end

  describe "parse errors" do
    # One row per distinct failure, asserting the class and that a line is reported.
    {
      "{ c'4 @ }" => [HeadMusic::Notation::LilyPond::ParseError, /Unexpected character/],
      "{ c'4 %{ open }" => [HeadMusic::Notation::LilyPond::ParseError, /Unterminated block comment/],
      %(\\header { title = "x } { c'1 }) => [HeadMusic::Notation::LilyPond::ParseError, /Unterminated string/],
      "{ c'4" => [HeadMusic::Notation::LilyPond::ParseError, /Unclosed "\{"/],
      "c'4 }" => [HeadMusic::Notation::LilyPond::ParseError, /Unexpected "\}"/],
      "c'4 d'4" => [HeadMusic::Notation::LilyPond::ParseError, /Expected a music expression/],
      "{ c'4 foo }" => [HeadMusic::Notation::LilyPond::ParseError, /Unexpected token/],
      "{ c'3 }" => [HeadMusic::Notation::LilyPond::ParseError, /Unrecognized duration/],
      "{ c'4.... }" => [HeadMusic::Notation::LilyPond::ParseError, /Too many dots/],
      "{ R1*4/0 }" => [HeadMusic::Notation::LilyPond::ParseError, /Zero denominator/],
      "{ c''''''' }" => [HeadMusic::Notation::LilyPond::ParseError, /out of range/],
      "{ \\key c }" => [HeadMusic::Notation::LilyPond::ParseError, /expects a pitch and a mode/],
      "{ \\key c \\blues }" => [HeadMusic::Notation::LilyPond::ParseError, /Unrecognized mode/],
      "{ \\time 4/3 }" => [HeadMusic::Notation::LilyPond::ParseError, /Invalid \\time signature/],
      "{ \\clef }" => [HeadMusic::Notation::LilyPond::ParseError, /\\clef expects/],
      "\\relative c'4 { c }" => [HeadMusic::Notation::LilyPond::ParseError, /\\relative expects a pitch/],
      "\\version 2 { c'1 }" => [HeadMusic::Notation::LilyPond::ParseError, /\\version expects/],
      "{ ~ c'4 }" => [HeadMusic::Notation::LilyPond::ParseError, /A tie must follow a note/],
      "{ c'4~ d'4 }" => [HeadMusic::Notation::LilyPond::ParseError, /same pitch/],
      "{ c'4~ r4 }" => [HeadMusic::Notation::LilyPond::ParseError, /must be followed by a note/],
      "{ c'4~ }" => [HeadMusic::Notation::LilyPond::ParseError, /must be followed by a note/],
      "{ c'1~ | c'1 }" => [HeadMusic::Notation::LilyPond::ParseError, /across bar checks/],
      "{ c'2 | }" => [HeadMusic::Notation::LilyPond::ParseError, /Bar check failed/],
      "<< \\new Staff { \\key g \\major c'1 } \\new Staff { \\key d \\major c1 } >>" => [HeadMusic::Notation::LilyPond::ParseError, /Conflicting \\key/],
      "{ <>4 }" => [HeadMusic::Notation::LilyPond::ParseError, /Empty chord/],
      "{ <c'4 e'>4 }" => [HeadMusic::Notation::LilyPond::ParseError, /cannot carry durations/],
      "{ c'4 \\tuplet 3/2 { d'8 e'8 f'8 } }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /"\\tuplet"/],
      "{ c'4-. }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /"-\."/],
      "{ c'4 s4 }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /"s4"/],
      "{ c'4*2 }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Duration multipliers/],
      "{ <c'*2 e'>4 }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Duration multipliers/],
      "{ R1*2 }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Multi-bar rests/],
      "melody = { c'1 }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Variable assignments/],
      "\\new Lyrics { c'1 }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /\\new Lyrics/],
      "<< { c'1 } { e'1 } >>" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /without \\new contexts/],
      "{ c'2 \\key d \\major d'2 }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /middle of a bar/],
      "{ c'1 } { d'1 }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Only one/],
      %(\\header { title = \\markup { "x" } } { c'1 }) => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /quoted strings/]
    }.each do |source, (error_class, message)|
      it "raises #{error_class.name.split("::").last} for #{source.inspect}" do
        expect { parse(source) }.to raise_error(error_class, message)
      end

      it "reports a line number for #{source.inspect}" do
        expect { parse(source) }.to raise_error(error_class, /\(line \d+\)/)
      end
    end

    it "raises only parse errors for any single-character deletion of the golden document" do
      expect(escaped_errors(LilyPondFixtures::AIR_DOCUMENT)).to be_empty
    end

    it "raises only parse errors for any single-character deletion of a relative excerpt" do
      source = "\\relative c' { \\key es \\major \\time 3/4 c4~ c8 d <es g>4 | r2. | R1*3/4 | }"
      expect(escaped_errors(source)).to be_empty
    end
  end

  describe "a note crossing a barline without a bar check" do
    it "parses, as LilyPond auto-splits it, even though the writer will refuse to re-render it" do
      composition = parse("{ c'2 d'1 e'2 }")
      expect(composition.voices.first.placements.map { |placement| placement.position.to_s }).to eq %w[1:1:000 1:3:000 2:3:000]
      expect { composition.to_lilypond }.to raise_error(HeadMusic::Notation::LilyPond::RenderError)
    end
  end
end
