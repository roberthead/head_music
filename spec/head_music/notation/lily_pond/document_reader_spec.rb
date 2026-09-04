require "spec_helper"

describe HeadMusic::Notation::LilyPond::DocumentReader do
  def read(source)
    tokens = HeadMusic::Notation::LilyPond::Lexer.new(source).tokens
    described_class.new(tokens).document
  end

  def voices(source)
    read(source).streams.map { |stream| [stream.role, stream.events.count(&:music?)] }
  end

  def pitches(source)
    read(source).streams.flat_map { |stream| stream.events.select(&:music?).map { |event| event.pitches&.map(&:to_s) } }
  end

  describe "the header" do
    it "maps title and composer" do
      document = read(%(\\header { title = "Air" composer = "Aloysius" } { c'1 }))
      expect([document.title, document.composer]).to eq ["Air", "Aloysius"]
    end

    it "leaves them nil when the header is absent" do
      document = read("{ c'1 }")
      expect([document.title, document.composer]).to eq [nil, nil]
    end

    it "unescapes the strings" do
      document = read(%(\\header { title = "The \\"Great\\" \\\\ Escape" } { c'1 }))
      expect(document.title).to eq %(The "Great" \\ Escape)
    end

    it "ignores other string fields" do
      document = read(%(\\header { tagline = "none" subtitle = "x" title = "Air" } { c'1 }))
      expect(document.title).to eq "Air"
    end

    it "accepts a header inside the score" do
      document = read(%(\\score { \\header { title = "Inner" } { c'1 } }))
      expect(document.title).to eq "Inner"
    end

    it "ignores a scheme value in a field it does not use" do
      document = read(%(\\header { tagline = ##f title = "Air" } { c'1 }))
      expect(document.title).to eq "Air"
    end

    it "ignores a markup value in a field it does not use" do
      document = read(%(\\header { subtitle = \\markup { \\italic "x" } composer = "Bach" } { c'1 }))
      expect(document.composer).to eq "Bach"
    end

    it "raises for a non-string value" do
      expect { read(%(\\header { title = \\markup { "x" } } { c'1 })) }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /values other than quoted strings/)
    end

    it "raises for a field with no value" do
      expect { read(%(\\header { subtitle = } { c'1 })) }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /name = "value"/)
    end

    it "raises for content that is not an assignment" do
      expect { read(%(\\header { \\include "x" } { c'1 })) }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /name = "value"/)
    end
  end

  describe "the envelope" do
    it "consumes a version" do
      expect(voices(%(\\version "2.24.0" { c'1 }))).to eq [[nil, 1]]
    end

    it "raises for a version without a string" do
      expect { read("\\version 2 { c'1 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /\\version expects a quoted version string/)
    end

    it "skips layout and midi blocks inside the score" do
      expect(voices("\\score { { c'1 } \\layout { indent = 0 } \\midi { } }")).to eq [[nil, 1]]
    end

    it "skips a top-level layout block" do
      expect(voices("\\layout { } { c'1 }")).to eq [[nil, 1]]
    end

    it "skips the scheme inside a layout block" do
      expect(voices("\\score { { c'1 } \\layout { indent = #0 ragged-right = ##t } }")).to eq [[nil, 1]]
    end

    it "skips a tempo inside a midi block" do
      expect(voices("\\score { { c'1 } \\midi { \\tempo 4 = 120 } }")).to eq [[nil, 1]]
    end

    it "skips a nested context block inside a layout block" do
      expect(voices("\\layout { \\context { \\Score \\override BarLine #'thickness = #2 } } { c'1 }")).to eq [[nil, 1]]
    end

    it "raises for a second score" do
      expect { read("\\score { { c'1 } } \\score { { d'1 } }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Only one \\score/)
    end

    it "raises for two top-level music expressions" do
      expect { read("{ c'1 } { d'1 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Only one \\score/)
    end

    it "raises for a variable assignment" do
      expect { read("melody = { c'1 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Variable assignments such as "melody ="/)
    end

    it "raises for a book" do
      expect { read("\\book { \\score { { c'1 } } }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /"\\book"/)
    end

    it "raises for notes outside braces" do
      expect { read("c'4 d'4") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Expected a music expression/)
    end

    it "raises for a stray word at the top level" do
      expect { read("hello { c'1 }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Expected a music expression/)
    end
  end

  describe "contexts" do
    it "yields one voice for a bare music expression" do
      expect(voices("{ c'4 d'4 }")).to eq [[nil, 2]]
    end

    it "yields no voice for an empty bare expression" do
      expect(read("{ }").streams).to be_empty
    end

    it "yields one voice for a Staff wrapping a Voice" do
      expect(voices(%(\\new Staff \\with { instrumentName = "Melody" } { \\new Voice { c'1 } }))).to eq [["Melody", 1]]
    end

    it "yields an empty explicit Staff as a silent voice" do
      expect(voices("\\new Staff { }")).to eq [[nil, 0]]
    end

    it "yields parallel staves in document order" do
      source = %(<< \\new Staff \\with { instrumentName = "A" } { c'1 } \\new Staff \\with { instrumentName = "B" } { d'1 } >>)
      expect(voices(source)).to eq [["A", 1], ["B", 1]]
    end

    it "raises for two sequential Voices in one Staff" do
      expect { read("\\new Staff { \\new Voice { c'1 } \\new Voice { d'1 } }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /follows a \\new context/)
    end

    it "raises for a context that follows music in a sequence" do
      expect { read("{ c'4 \\new Staff { d'4 } }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /follows music/)
    end

    it "reads a lone context inside a sequence" do
      expect(voices("{ \\new Staff { c'4 d'4 } }")).to eq [[nil, 2]]
    end

    it "gives a Voice its own instrumentName over the Staff's" do
      source = %(\\new Staff \\with { instrumentName = "Staff" } { \\new Voice \\with { instrumentName = "Voice" } { c'1 } })
      expect(voices(source)).to eq [["Voice", 1]]
    end

    it "consumes a context name" do
      expect(voices(%(\\new Voice = "melody" { c'1 }))).to eq [[nil, 1]]
    end

    it "ignores other with assignments" do
      expect(voices(%(\\new Staff \\with { shortInstrumentName = "M" instrumentName = "Melody" } { c'1 }))).to eq [["Melody", 1]]
    end

    it "raises for a with block that is not assignments" do
      expect { read(%(\\new Staff \\with { \\consists "Foo" } { c'1 })) }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /\\with expects/)
    end

    it "raises for an unquoted context name" do
      expect { read("\\new Voice = melody { c'1 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /quoted string/)
    end

    it "raises for other context types" do
      expect { read("\\new Lyrics { c'1 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /\\new Lyrics contexts are not supported/)
    end

    it "raises for a new without a type" do
      expect { read("\\new { c'1 }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /context type/)
    end

    it "raises for parallel music without contexts" do
      expect { read("<< { c'1 } { e'1 } >>") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Simultaneous music without \\new contexts/)
    end

    it "raises for key and time in a context that yields no voice" do
      expect { read("\\new Staff { \\key g \\major \\new Voice { c'1 } }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /outside a voice/)
    end

    it "accepts a relative wrapper around a parallel item" do
      expect(pitches("<< \\relative c' \\new Staff { c d } >>")).to eq [%w[C4], %w[D4]]
    end

    it "accepts an absolute wrapper" do
      expect(pitches("\\relative c' { c \\absolute { c } }")).to eq [%w[C4], %w[C3]]
    end
  end

  describe "pitch modes" do
    it "reads absolute pitches by default" do
      expect(pitches("{ c d' e, }")).to eq [%w[C3], %w[D4], %w[E2]]
    end

    it "reads relative pitches from the reference" do
      expect(pitches("\\relative c' { g a b c d c b g }").flatten).to eq %w[G3 A3 B3 C4 D4 C4 B3 G3]
    end

    it "defaults the relative reference to f" do
      expect(pitches("\\relative { c d }")).to eq [%w[C3], %w[D3]]
    end

    it "accepts an altered reference" do
      expect(pitches("\\relative cis' { c }")).to eq [%w[C4]]
    end

    it "keeps the reference across a rest" do
      expect(pitches("\\relative c' { g r d }")).to eq [%w[G3], nil, %w[D3]]
    end

    it "nests relative blocks" do
      expect(pitches("\\relative c' { c \\relative c'' { c } c }")).to eq [%w[C4], %w[C5], %w[C4]]
    end

    it "does not let a key command move the reference" do
      expect(pitches("\\relative c' { \\key b \\major c }")).to eq [%w[C4]]
    end

    it "raises for a reference with a duration" do
      expect { read("\\relative c'4 { c }") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /\\relative expects a pitch/)
    end

    it "raises for parallel music inside relative" do
      expect { read("\\relative c' << \\new Staff { c } >>") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Simultaneous music inside \\relative/)
    end
  end

  describe "music items" do
    it "reads rests without pitches" do
      event = read("{ r4 }").streams.first.events.first
      expect([event.kind, event.pitches, event.rhythmic_value.to_s]).to eq [:rest, nil, "quarter"]
    end

    it "reads a whole-bar rest's fraction" do
      event = read("{ R1*3/4 }").streams.first.events.first
      expect([event.kind, event.fraction]).to eq [:whole_bar_rest, Rational(3, 4)]
    end

    it "reads a chord as one note with several pitches" do
      expect(pitches("{ <c' e' g'>2 }")).to eq [%w[C4 E4 G4]]
    end

    it "puts the chord's duration on the event" do
      expect(read("{ <c' e'>2. }").streams.first.events.first.rhythmic_value.to_s).to eq "dotted half"
    end

    it "carries duration into and out of a chord" do
      values = read("{ c'8 <c' e'> d'2 e' }").streams.first.events.map { |event| event.rhythmic_value.to_s }
      expect(values).to eq %w[eighth eighth half half]
    end

    it "reads nested braces" do
      expect(voices("{ c'4 { d'4 { e'4 } } }")).to eq [[nil, 3]]
    end

    it "folds a tie" do
      expect(read("{ c'2~ c'4 }").streams.first.events.map { |event| event.rhythmic_value.to_s }).to eq ["half tied to quarter"]
    end

    it "records bar checks" do
      expect(read("{ c'1 | d'1 | }").streams.first.events.map(&:kind)).to eq %i[note bar_check note bar_check]
    end

    it "consumes clef commands with word, string, and note-shaped names" do
      expect(voices(%({ \\clef treble \\clef "bass" \\clef alto \\clef f c'1 }))).to eq [[nil, 1]]
    end

    it "raises for a clef without a name" do
      expect { read("{ \\clef }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /\\clef expects a clef name/)
    end

    it "raises for an empty chord" do
      expect { read("{ <>4 }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Empty chord/)
    end

    it "raises for a chord note with a duration" do
      expect { read("{ <c'4 e'>4 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Chord notes cannot carry durations/)
    end

    it "raises for a chord note with a multiplier" do
      expect { read("{ <c'*2 e'>4 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Duration multipliers/)
    end

    it "raises for a rest inside a chord" do
      expect { read("{ <c' r>4 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unexpected token "r" inside a chord/)
    end

    {"a note" => "{ c'4*3 }", "a rest" => "{ r4*3 }", "a chord" => "{ <c' e'>4*3 }"}.each do |kind, source|
      it "raises for a multiplier on #{kind}" do
        expect { read(source) }
          .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Duration multipliers/)
      end
    end

    it "raises for nesting beyond the depth bound, at the opener that crossed it" do
      source = "{\n" * 1001 + "c'1" + " }" * 1001
      expect { read(source) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /nested too deeply \(line 1001\)/)
    end

    it "reads nesting up to the depth bound" do
      source = "{ " * 1000 + "c'1" + " }" * 1000
      expect(voices(source)).to eq [[nil, 1]]
    end

    it "bounds relative nesting" do
      expect { read("\\relative " * 1001 + "{ c'1 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /nested too deeply/)
    end

    it "bounds context nesting" do
      expect { read("\\new Staff " * 1001 + "{ c'1 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /nested too deeply/)
    end

    it "raises for a stray word" do
      expect { read("{ c'4 foo }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unexpected token "foo"/)
    end

    it "raises for a stray number" do
      expect { read("{ c'4 4 }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unexpected token "4"/)
    end

    it "raises for an envelope command inside music" do
      expect { read("{ c'4 \\score { } }") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unexpected \\score inside music/)
    end

    %w[tuplet times chordmode lyricmode addlyrics partial bar tempo mark repeat transpose fixed language grace f p melody].each do |command|
      it "raises for \\#{command} as unsupported" do
        expect { read("{ c'4 \\#{command} }") }
          .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Unsupported LilyPond feature "\\#{command}"/)
      end
    end
  end

  describe "key and time" do
    it "records a key change with its line" do
      event = read("{\n\\key g \\major c'1 }").streams.first.events.first
      expect([event.kind, event.key_signature.to_s, event.line]).to eq [:key, "1 sharp", 2]
    end

    it "records a meter change" do
      event = read("{ \\time 3/4 c'2. }").streams.first.events.first
      expect([event.kind, event.meter.to_s]).to eq [:time, "3/4"]
    end

    it "exposes the first key and meter" do
      document = read("{ \\clef treble \\key d \\major \\time 6/8 c'2. }")
      expect([document.first_key_signature.to_s, document.first_meter.to_s]).to eq ["2 sharps", "6/8"]
    end

    it "takes the first key from a later stream when the first has none" do
      document = read("<< \\new Staff { c'1 } \\new Staff { \\key d \\major c'1 } >>")
      expect(document.first_key_signature.to_s).to eq "2 sharps"
    end

    it "ignores a key that follows music when seeding" do
      document = read("{ c'1 | \\key d \\major c'1 }")
      expect(document.first_key_signature).to be_nil
    end

    it "raises for a key at the end of input with the command's line" do
      expect { read("{ c'1\n\\key") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /\\key expects a pitch and a mode \(line 2\)/)
    end

    it "raises for a time at the end of input with the command's line" do
      expect { read("{ c'1\n\\time") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Invalid \\time signature "" \(line 2\)/)
    end
  end
end
