require "spec_helper"

describe HeadMusic::Notation::ABC::Parser do
  def parse(abc_string)
    HeadMusic::Notation::ABC.parse(abc_string)
  end

  def parse_body(body)
    parse(<<~ABC)
      X:1
      M:4/4
      L:1/4
      K:C
      #{body}
    ABC
  end

  describe "input validation" do
    it "raises for nil input" do
      expect { parse(nil) }.to raise_error(HeadMusic::Notation::ABC::ParseError)
    end

    it "raises for empty input" do
      expect { parse("") }.to raise_error(HeadMusic::Notation::ABC::ParseError)
    end

    it "raises for whitespace-only input" do
      expect { parse(" \n\t\n") }.to raise_error(HeadMusic::Notation::ABC::ParseError)
    end
  end

  describe "#composition" do
    it "memoizes the composition" do
      parser = described_class.new("X:1\nK:C\nCDE|\n")
      expect(parser.composition).to equal(parser.composition)
    end
  end

  describe "content after the tune body" do
    it "raises and suggests parse_book when a second tune follows" do
      expect { parse("X:1\nK:C\nCDEF|\n\nX:2\nK:C\nGABc|\n") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /parse_book.*line 5/)
    end

    it "raises for stray text after the tune" do
      expect { parse("X:1\nK:C\nCDEF|\n\nstray text\n") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /after the tune body/)
    end

    it "allows trailing blank lines" do
      expect(parse("X:1\nK:C\nCDEF|\n\n\n").voices.first.placements.length).to eq 4
    end

    it "allows trailing comment lines after the tune" do
      expect(parse("X:1\nK:C\nCDEF|\n\n% the end\n").voices.first.placements.length).to eq 4
    end
  end

  describe "a single-voice tune" do
    subject(:composition) { parse_body("CDEF|GABc|") }

    let(:voice) { composition.voices.first }

    it "creates a single voice with a nil role" do
      expect(composition.voices.map(&:role)).to eq [nil]
    end

    it "places each note with its pitch" do
      expect(voice.pitches.map(&:to_s)).to eq %w[C4 D4 E4 F4 G4 A4 B4 C5]
    end

    it "places each note with its rhythmic value" do
      expect(voice.placements.map { |placement| placement.rhythmic_value.name }.uniq).to eq ["quarter"]
    end

    it "places the first note at the start of bar one" do
      expect(voice.placements.first.position.to_s).to eq "1:1:000"
    end

    it "rolls placements over into the second bar" do
      expect(voice.placements[4].position.to_s).to eq "2:1:000"
    end
  end

  describe "note lengths" do
    subject(:composition) { parse_body("C2 D E/|") }

    let(:names) { composition.voices.first.placements.map { |placement| placement.rhythmic_value.name } }

    it "resolves multipliers against the unit note length" do
      expect(names).to eq ["half", "quarter", "eighth"]
    end
  end

  describe "rests" do
    subject(:composition) { parse_body("C z D|") }

    let(:voice) { composition.voices.first }

    it "places the rest with no pitch" do
      expect(voice.placements[1].pitch).to be_nil
    end

    it "marks the placement as a rest" do
      expect(voice.placements[1]).to be_rest
    end

    it "advances the cursor past the rest" do
      expect(voice.placements[2].position.to_s).to eq "1:3:000"
    end
  end

  describe "header mapping" do
    subject(:composition) { parse(<<~ABC) }
      X:1
      T:Test Tune
      C:Trad.
      O:Ireland
      N:first note
      N:second note
      M:3/4
      L:1/8
      K:D
      ABc|
    ABC

    it "maps the title to the name" do
      expect(composition.name).to eq "Test Tune"
    end

    it "maps the composer" do
      expect(composition.composer).to eq "Trad."
    end

    it "maps the origin" do
      expect(composition.origin).to eq "Ireland"
    end

    it "maps annotations to unpositioned comments in order" do
      expect(composition.comments.map(&:text)).to eq ["first note", "second note"]
    end

    it "leaves the comments unpositioned" do
      expect(composition.comments.map(&:position)).to all(be_nil)
    end

    it "maps the key signature" do
      expect(composition.key_signature.name).to eq "D major"
    end

    it "maps the meter" do
      expect(composition.meter.to_s).to eq "3/4"
    end

    it "applies the key signature to unmarked notes" do
      expect(composition.voices.first.pitches.map(&:to_s)).to eq %w[A4 B4 C♯5]
    end

    context "without a title" do
      subject(:composition) { parse("X:1\nK:C\nCDE|\n") }

      it "defaults the composition name" do
        expect(composition.name).to eq "Composition"
      end
    end
  end

  describe "multiple voices" do
    subject(:composition) { parse(<<~ABC) }
      X:1
      V:1
      V:2
      K:C
      V:1
      CD
      V:2
      GA
      V:1
      EF
    ABC

    let(:first_voice) { composition.voices.first }
    let(:second_voice) { composition.voices.last }

    it "creates a voice for each header V: field" do
      expect(composition.voices.map(&:role)).to eq %w[1 2]
    end

    it "routes placements to the voice selected by body V: lines" do
      expect(second_voice.pitches.map(&:to_s)).to eq %w[G4 A4]
    end

    it "resumes a voice's own cursor when switching back" do
      expect(first_voice.pitches.map(&:to_s)).to eq %w[C4 D4 E4 F4]
    end

    it "keeps each voice's placements sequential from bar one" do
      expect(second_voice.placements.first.position.to_s).to eq "1:1:000"
    end

    context "when a body V: names an unknown voice" do
      subject(:composition) { parse("X:1\nK:C\nV:9\nCDE|\n") }

      it "creates the voice on demand" do
        expect(composition.voices.map(&:role)).to eq ["9"]
      end
    end

    context "with accidentals in one voice" do
      subject(:composition) { parse(<<~ABC) }
        X:1
        K:C
        V:1
        ^FF
        V:2
        F
      ABC

      it "keeps accidental state independent between voices" do
        pitches = composition.voices.map { |voice| voice.pitches.map(&:to_s) }
        expect(pitches).to eq [%w[F♯4 F♯4], %w[F4]]
      end
    end
  end

  describe "broken rhythm" do
    it "dots the left note and halves the right note for >" do
      composition = parse_body("A>B|")
      names = composition.voices.first.placements.map { |placement| placement.rhythmic_value.name }
      expect(names).to eq ["dotted quarter", "eighth"]
    end

    it "halves the left note and dots the right note for <" do
      composition = parse_body("A<B|")
      names = composition.voices.first.placements.map { |placement| placement.rhythmic_value.name }
      expect(names).to eq ["eighth", "dotted quarter"]
    end

    it "raises for a leading broken rhythm mark" do
      expect { parse_body(">AB|") }.to raise_error(HeadMusic::Notation::ABC::ParseError)
    end

    it "raises for a broken rhythm mark before a bar line" do
      expect { parse_body("AB>|") }.to raise_error(HeadMusic::Notation::ABC::ParseError)
    end

    it "raises for a trailing broken rhythm mark" do
      expect { parse_body("AB>") }.to raise_error(HeadMusic::Notation::ABC::ParseError)
    end

    it "raises for a broken rhythm mark before a rest" do
      expect { parse_body("A>z|") }.to raise_error(HeadMusic::Notation::ABC::ParseError)
    end
  end

  describe "ties" do
    def parse_compound(body)
      parse(<<~ABC)
        X:1
        M:6/8
        L:1/8
        K:C
        #{body}
      ABC
    end

    it "fuses a tied pair into a single placement" do
      voice = parse_compound("E3-E2 G |]").voices.first
      expect(voice.placements.length).to eq 2
    end

    it "honors the authored split instead of the greedy decomposition" do
      value = parse_compound("E3-E2 G |]").voices.first.placements.first.rhythmic_value
      expect(value.name).to eq "dotted quarter tied to quarter"
    end

    it "differs from the greedy split of the same total duration" do
      greedy = parse_compound("E5 G |]").voices.first.placements.first.rhythmic_value
      authored = parse_compound("E3-E2 G |]").voices.first.placements.first.rhythmic_value
      expect(greedy.name).to eq "half tied to eighth"
      expect(authored.total_value).to eq greedy.total_value
      expect(authored.name).not_to eq greedy.name
    end

    it "chains three tied notes into one nested value" do
      value = parse_compound("C2-C2-C2 |]").voices.first.placements.first.rhythmic_value
      expect(value.name).to eq "quarter tied to quarter tied to quarter"
    end

    it "ties a note across the whole bar in simple meter" do
      value = parse_body("C3-C |").voices.first.placements.first.rhythmic_value
      expect(value.name).to eq "dotted half tied to quarter"
    end

    it "raises when the tied notes are different pitches" do
      expect { parse_compound("E3-D2 |]") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /same pitch/)
    end

    it "raises for a tie across a barline" do
      expect { parse_compound("E3-|E3 |]") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /across barlines/)
    end

    it "raises for a dangling tie at the end of the tune" do
      expect { parse_compound("E3-") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /followed by a note/)
    end

    it "raises for a tie with no preceding note" do
      expect { parse_compound("-E3 |]") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /must follow a note/)
    end

    it "raises for a tie to a rest" do
      expect { parse_compound("E3-z |]") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /followed by a note/)
    end

    it "raises for a tie followed by a broken-rhythm mark" do
      expect { parse_compound("A->A |]") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /followed by a note/)
    end
  end

  describe "accidental persistence" do
    subject(:composition) { parse_body("^FF|F2|") }

    it "persists an accidental to the end of the bar and resets at the bar line" do
      expect(composition.voices.first.pitches.map(&:to_s)).to eq %w[F♯4 F♯4 F4]
    end
  end

  describe "repeats" do
    context "with a repeated section spanning the whole tune" do
      subject(:composition) { parse_body("|:CDEF:|") }

      it "starts the repeat on bar one" do
        expect(composition.bars(1).last.starts_repeat?).to be true
      end

      it "ends the repeat on bar one after two plays" do
        expect(composition.bars(1).last.ends_repeat_after_num_plays).to eq 2
      end
    end

    context "with a mid-tune repeat ending" do
      subject(:composition) { parse_body("CDEF|GABc:|") }

      it "ends the repeat on the completed bar" do
        expect(composition.bars(2).last.ends_repeat_after_num_plays).to eq 2
      end

      it "leaves earlier bars without a repeat ending" do
        expect(composition.bars(1).first.ends_repeat?).to be false
      end
    end

    context "with a double repeat bar" do
      subject(:composition) { parse_body("CDEF::GABc|]") }

      it "ends a repeat on the completed bar" do
        expect(composition.bars(1).first.ends_repeat_after_num_plays).to eq 2
      end

      it "starts a repeat on the entered bar" do
        expect(composition.bars(2).last.starts_repeat?).to be true
      end
    end

    it "ignores a repeat ending before any placements" do
      composition = parse_body(":|CDEF|")
      expect(composition.bars(1).first.ends_repeat?).to be false
    end

    it "sets no repeat flags for plain and section bar lines" do
      composition = parse_body("CDEF|GABc|]")
      bars = composition.bars(2)
      expect(bars.map(&:starts_repeat?) + bars.map(&:ends_repeat?)).to all(be false)
    end
  end

  describe "voltas" do
    context "with first and second endings" do
      subject(:composition) { parse_body("|:CDEF|1 GABc:|2 cdef|]") }

      let(:bars) { composition.bars(3) }

      it "starts the repeat on bar one" do
        expect(bars[0].starts_repeat?).to be true
      end

      it "tags the first-ending bar with pass one" do
        expect(bars[1].plays_on_passes).to eq [1]
      end

      it "ends the repeat on the first-ending bar" do
        expect(bars[1].ends_repeat_after_num_plays).to eq 2
      end

      it "tags the second-ending bar with pass two" do
        expect(bars[2].plays_on_passes).to eq [2]
      end

      it "leaves the repeated bar untagged" do
        expect(bars[0].plays_on_passes).to be_nil
      end
    end

    context "with a multi-bar volta" do
      subject(:composition) { parse_body("CDEF|1 GABc|cdef:|[2 gabc|]") }

      let(:bars) { composition.bars(4) }

      it "tags every bar under the first ending" do
        expect(bars[1..2].map(&:plays_on_passes)).to eq [[1], [1]]
      end

      it "ends the repeat on the last first-ending bar" do
        expect(bars[2].ends_repeat_after_num_plays).to eq 2
      end

      it "tags the second-ending bar" do
        expect(bars[3].plays_on_passes).to eq [2]
      end
    end

    context "with a pass list" do
      subject(:composition) { parse_body("CDEF|1,3 GABc:|") }

      it "carries the full pass list onto the bar" do
        expect(composition.bars(2).last.plays_on_passes).to eq [1, 3]
      end
    end

    context "when the tune ends inside a volta" do
      subject(:composition) { parse_body("CDEF|1 GABc:|2 cdef") }

      it "tags the final bar at end of input" do
        expect(composition.bars(3).last.plays_on_passes).to eq [2]
      end
    end
  end

  describe "unsupported features" do
    {
      "a quoted chord symbol" => ['"Am" C|', '"Am"'],
      "a grace note" => ["{g}A|", "{g}"],
      "a slur" => ["(AB)|", "("],
      "a tuplet" => ["(3ABC|", "(3"],
      "a decoration" => ["!trill!A|", "!trill!"],
      "a double broken rhythm" => ["A>>B|", ">>"],
      "a multi-bar rest" => ["Z4|", "Z4"],
      "an invisible rest" => ["x2|", "x2"],
      "an inline field" => ["[K:G]A|", "[K:G]"],
      "a lyrics line" => ["CDEF|\nw:la la la", "w:la la la"]
    }.each do |feature, (body, lexeme)|
      it "raises for #{feature}, naming the lexeme and line" do
        expect { parse_body(body) }.to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError) do |error|
          # The message quotes the lexeme with String#inspect, which
          # escapes any double quotes the lexeme itself contains.
          expect(error.message).to include(lexeme.inspect[1..-2])
          expect(error.snippet).to eq lexeme
          expect(error.message).to match(/line \d+/)
        end
      end
    end

    it "reports the line number of the unsupported token" do
      expect { parse("X:1\nK:C\nCDEF|\n{g}A|\n") }
        .to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /\{g\}.*line 4/)
    end

    it "raises before any interpretation when an unsupported token appears late in the body" do
      expect { parse_body("CDEF|GABc|{g}A|") }
        .to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /\{g\}/)
    end
  end

  describe "chords" do
    subject(:composition) { parse(<<~ABC) }
      X:1
      T:Chorale Fragment
      M:4/4
      L:1/4
      K:C
      [CEG]2 [DFA]2 | [EGC']4 |]
    ABC

    let(:voice) { composition.voices.first }

    it "places each chord as one placement holding the bracketed pitches" do
      expect(voice.placements.map { |placement| [placement.position.to_s, placement.pitches.map(&:to_s)] })
        .to eq [["1:1:000", %w[C4 E4 G4]], ["1:3:000", %w[D4 F4 A4]], ["2:1:000", %w[E4 G4 C5]]]
    end

    it "marks the placements as chords" do
      expect(voice.placements).to all(be_chord)
    end

    it "applies the length after the bracket to the whole chord" do
      expect(voice.placements.map { |placement| placement.rhythmic_value.name })
        .to eq ["half", "half", "whole"]
    end

    it "parses a single-note bracket as an ordinary note placement" do
      placement = parse_body("[C] D|").voices.first.placements.first
      expect([placement.note?, placement.chord?, placement.pitches.map(&:to_s)])
        .to eq [true, false, ["C4"]]
    end

    it "reads uniform per-note lengths as the chord's length" do
      placement = parse_body("[C2E2G2]|").voices.first.placements.first
      expect(placement.rhythmic_value.name).to eq "half"
    end

    it "multiplies uniform inner lengths with the outer length (ABC 2.1 sec. 4.17)" do
      inner_outer = parse_body("[C2E2G2]3|").voices.first.placements.first
      outer_only = parse_body("[CEG]6|").voices.first.placements.first
      expect(inner_outer.rhythmic_value).to eq outer_only.rhythmic_value
    end

    it "treats differently-spelled equal inner lengths as uniform" do
      placement = parse_body("[C4/2E2G2]|").voices.first.placements.first
      expect(placement.rhythmic_value.name).to eq "half"
    end

    it "raises when bracketed notes have unequal lengths" do
      expect { parse_body("[C2EG]|") }.to raise_error(
        HeadMusic::Notation::ABC::ParseError,
        'Chord notes must share one length; write it after the bracket ("[CEG]2") ' \
        'or repeat it on every note ("[C2E2G2]") (line 5)'
      )
    end

    it "raises when two bracketed notes resolve to the same pitch" do
      expect { parse_body("[CEC]|") }.to raise_error(
        HeadMusic::Notation::ABC::ParseError, "Chord pitches must be unique (line 5)"
      )
    end

    it "allows the same letter an octave apart" do
      placement = parse_body("[Cc]|").voices.first.placements.first
      expect([placement.chord?, placement.pitches.map(&:to_s)]).to eq [true, %w[C4 C5]]
    end

    it "applies broken rhythm across two chords" do
      placements = parse_body("[CEG]>[DFA]|").voices.first.placements
      expect(placements.map { |placement| placement.rhythmic_value.name })
        .to eq ["dotted quarter", "eighth"]
    end

    it "keeps both sides of a broken rhythm as chords" do
      placements = parse_body("[CEG]>[DFA]|").voices.first.placements
      expect(placements).to all(be_chord)
    end

    it "still rejects an inline field next to a chord as unsupported, not a chord" do
      expect { parse_body("[CEG] [K:G] A|") }
        .to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /\[K:G\]/)
    end

    it "persists an accidental inside a chord for the rest of the bar" do
      placements = parse_body("[^FA] F|").voices.first.placements
      expect(placements.map { |placement| placement.pitches.map(&:to_s) })
        .to eq [%w[F♯4 A4], %w[F♯4]]
    end

    it "resets a chord accidental at the bar line" do
      placements = parse_body("[^FA] F|F|").voices.first.placements
      expect(placements.last.pitches.map(&:to_s)).to eq %w[F4]
    end
  end

  describe "beam breaks" do
    def placements(body, meter: "C")
      parse(<<~ABC).voices.first.placements.sort_by(&:position)
        X:1
        L:1/8
        M:#{meter}
        K:C
        #{body}
      ABC
    end

    def flags(body, meter: "C")
      placements(body, meter: meter).map(&:beam_break_before)
    end

    it "beams a run of adjacent notes as one group" do
      expect(flags("CCCC")).to eq [nil, false, false, false]
    end

    it "breaks the beam where the author leaves a space" do
      expect(flags("CC CC")).to eq [nil, false, true, false]
    end

    it "honors authored grouping verbatim across a beat" do
      expect(flags("CCC DDD", meter: "6/8")).to eq [nil, false, false, true, false, false]
    end

    it "restarts adjacency after a rest" do
      # The rest resets adjacency, so the following note is not joined
      # (`false`) to the pre-rest note. The authored space before that note
      # (`z C`) still emits its own beam break, so it forces a break (`true`)
      # rather than falling through to the meter default (`nil`).
      expect(flags("CC z CC")).to eq [nil, false, nil, true, false]
    end

    it "fuses a tied pair into one placement whose beam flag is nil" do
      expect(placements("C-C DD").length).to eq 3
    end

    it "carries the head's flag through a tie and breaks before a spaced note" do
      expect(flags("C-C DD")).to eq [nil, true, false]
    end

    it "keeps a broken-rhythm pair beamed and does not reset adjacency" do
      expect(flags("C>D EF")).to eq [nil, false, true, false]
    end
  end
end
