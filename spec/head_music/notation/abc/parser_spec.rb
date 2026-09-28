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

  describe "#flow" do
    it "memoizes the flow" do
      parser = described_class.new("X:1\nK:C\nCDE|\n")
      expect(parser.flow).to equal(parser.flow)
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
      expect(parse("X:1\nK:C\nCDEF|\n\n\n").voices.first.voice_events.length).to eq 4
    end

    it "allows trailing comment lines after the tune" do
      expect(parse("X:1\nK:C\nCDEF|\n\n% the end\n").voices.first.voice_events.length).to eq 4
    end
  end

  describe "a single-voice tune" do
    subject(:flow) { parse_body("CDEF|GABc|") }

    let(:voice) { flow.voices.first }

    it "creates a single voice with a nil role" do
      expect(flow.voices.map(&:role)).to eq [nil]
    end

    it "places each note with its pitch" do
      expect(voice.pitches.map(&:to_s)).to eq %w[C4 D4 E4 F4 G4 A4 B4 C5]
    end

    it "places each note with its rhythmic value" do
      expect(voice.voice_events.map { |voice_event| voice_event.rhythmic_value.name }.uniq).to eq ["quarter"]
    end

    it "places the first note at the start of bar one" do
      expect(voice.voice_events.first.position.to_s).to eq "1:1:000"
    end

    it "rolls voice events over into the second bar" do
      expect(voice.voice_events[4].position.to_s).to eq "2:1:000"
    end
  end

  describe "note lengths" do
    subject(:flow) { parse_body("C2 D E/|") }

    let(:names) { flow.voices.first.voice_events.map { |voice_event| voice_event.rhythmic_value.name } }

    it "resolves multipliers against the unit note length" do
      expect(names).to eq ["half", "quarter", "eighth"]
    end
  end

  describe "rests" do
    subject(:flow) { parse_body("C z D|") }

    let(:voice) { flow.voices.first }

    it "places the rest with no pitch" do
      expect(voice.voice_events[1].pitch).to be_nil
    end

    it "marks the voice event as a rest" do
      expect(voice.voice_events[1]).to be_rest
    end

    it "advances the cursor past the rest" do
      expect(voice.voice_events[2].position.to_s).to eq "1:3:000"
    end
  end

  describe "header mapping" do
    subject(:flow) { parse(<<~ABC) }
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
      expect(flow.name).to eq "Test Tune"
    end

    it "maps the composer" do
      expect(flow.composer).to eq "Trad."
    end

    it "maps the origin" do
      expect(flow.origin).to eq "Ireland"
    end

    it "maps annotations to unpositioned comments in order" do
      expect(flow.comments.map(&:text)).to eq ["first note", "second note"]
    end

    it "leaves the comments unpositioned" do
      expect(flow.comments.map(&:position)).to all(be_nil)
    end

    it "maps the key signature" do
      expect(flow.key_signature.name).to eq "D major"
    end

    it "maps the meter" do
      expect(flow.meter.to_s).to eq "3/4"
    end

    it "applies the key signature to unmarked notes" do
      expect(flow.voices.first.pitches.map(&:to_s)).to eq %w[A4 B4 C♯5]
    end

    context "without a title" do
      subject(:flow) { parse("X:1\nK:C\nCDE|\n") }

      it "defaults the flow name" do
        expect(flow.name).to eq "Composition"
      end
    end
  end

  describe "multiple voices" do
    subject(:flow) { parse(<<~ABC) }
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

    let(:first_voice) { flow.voices.first }
    let(:second_voice) { flow.voices.last }

    it "creates a voice for each header V: field" do
      expect(flow.voices.map(&:role)).to eq %w[1 2]
    end

    it "routes voice events to the voice selected by body V: lines" do
      expect(second_voice.pitches.map(&:to_s)).to eq %w[G4 A4]
    end

    it "resumes a voice's own cursor when switching back" do
      expect(first_voice.pitches.map(&:to_s)).to eq %w[C4 D4 E4 F4]
    end

    it "keeps each voice's voice events sequential from bar one" do
      expect(second_voice.voice_events.first.position.to_s).to eq "1:1:000"
    end

    context "when a body V: names an unknown voice" do
      subject(:flow) { parse("X:1\nK:C\nV:9\nCDE|\n") }

      it "creates the voice on demand" do
        expect(flow.voices.map(&:role)).to eq ["9"]
      end
    end

    context "with accidentals in one voice" do
      subject(:flow) { parse(<<~ABC) }
        X:1
        K:C
        V:1
        ^FF
        V:2
        F
      ABC

      it "keeps accidental state independent between voices" do
        pitches = flow.voices.map { |voice| voice.pitches.map(&:to_s) }
        expect(pitches).to eq [%w[F♯4 F♯4], %w[F4]]
      end
    end
  end

  describe "broken rhythm" do
    it "dots the left note and halves the right note for >" do
      flow = parse_body("A>B|")
      names = flow.voices.first.voice_events.map { |voice_event| voice_event.rhythmic_value.name }
      expect(names).to eq ["dotted quarter", "eighth"]
    end

    it "halves the left note and dots the right note for <" do
      flow = parse_body("A<B|")
      names = flow.voices.first.voice_events.map { |voice_event| voice_event.rhythmic_value.name }
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

    it "fuses a tied pair into a single voice event" do
      voice = parse_compound("E3-E2 G |]").voices.first
      expect(voice.voice_events.length).to eq 2
    end

    it "honors the authored split instead of the greedy decomposition" do
      value = parse_compound("E3-E2 G |]").voices.first.voice_events.first.rhythmic_value
      expect(value.name).to eq "dotted quarter tied to quarter"
    end

    it "differs from the greedy split of the same total duration" do
      greedy = parse_compound("E5 G |]").voices.first.voice_events.first.rhythmic_value
      authored = parse_compound("E3-E2 G |]").voices.first.voice_events.first.rhythmic_value
      expect(greedy.name).to eq "half tied to eighth"
      expect(authored.total_value).to eq greedy.total_value
      expect(authored.name).not_to eq greedy.name
    end

    it "chains three tied notes into one nested value" do
      value = parse_compound("C2-C2-C2 |]").voices.first.voice_events.first.rhythmic_value
      expect(value.name).to eq "quarter tied to quarter tied to quarter"
    end

    it "ties a note across the whole bar in simple meter" do
      value = parse_body("C3-C |").voices.first.voice_events.first.rhythmic_value
      expect(value.name).to eq "dotted half tied to quarter"
    end

    it "raises when the tied notes are different pitches" do
      expect { parse_compound("E3-D2 |]") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /same pitch/)
    end

    it "ties a note across a barline into one voice event" do
      voice_events = parse_compound("E3-|E3 |]").voices.first.voice_events
      expect(voice_events.length).to eq 1
      expect(voice_events.first.rhythmic_value.name).to eq "dotted quarter tied to dotted quarter"
    end

    it "sustains a tie across a barline through the next downbeat" do
      voice = parse_body("z2 A2-|A2 D2 |]").voices.first
      expect(voice.notes.map { |note| note.position.code }).to eq %w[1:3:000 2:3:000]
      expect(voice.note_at(HeadMusic::Content::Position.new(voice.flow, "2:1")).pitch.to_s).to eq "A4"
    end

    it "still rejects a tie across a barline onto a different pitch" do
      expect { parse_compound("E3-|D3 |]") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /same pitch/)
    end

    it "carries an accidental across the barline with the tie" do
      note = parse_body("^D2-|D2 z2 |]").voices.first.notes.first
      expect(note.pitch.to_s).to eq "D♯4"
      expect(note.rhythmic_value.name).to eq "half tied to half"
    end

    it "tags a repeat opened after a tied barline on the right bar" do
      flow = parse_body("C2 D2-|:D2 E2:|G4 |]")
      expect(flow.bars.select(&:starts_repeat?).map(&:number)).to eq [2]
      expect(flow.bars.select(&:ends_repeat_after_num_plays).map(&:number)).to eq [2]
    end

    it "tags a volta entered through a tied barline on the right bar" do
      flow = parse_body("C4|E4-|[1 E4:|[2 G4 |]")
      expect(flow.bars.map(&:plays_on_passes)).to eq [nil, nil, [1], [2]]
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
    subject(:flow) { parse_body("^FF|F2|") }

    it "persists an accidental to the end of the bar and resets at the bar line" do
      expect(flow.voices.first.pitches.map(&:to_s)).to eq %w[F♯4 F♯4 F4]
    end
  end

  describe "repeats" do
    context "with a repeated section spanning the whole tune" do
      subject(:flow) { parse_body("|:CDEF:|") }

      it "starts the repeat on bar one" do
        expect(flow.bars(1).last.starts_repeat?).to be true
      end

      it "ends the repeat on bar one after two plays" do
        expect(flow.bars(1).last.ends_repeat_after_num_plays).to eq 2
      end
    end

    context "with a mid-tune repeat ending" do
      subject(:flow) { parse_body("CDEF|GABc:|") }

      it "ends the repeat on the completed bar" do
        expect(flow.bars(2).last.ends_repeat_after_num_plays).to eq 2
      end

      it "leaves earlier bars without a repeat ending" do
        expect(flow.bars(1).first.ends_repeat?).to be false
      end
    end

    context "with a double repeat bar" do
      subject(:flow) { parse_body("CDEF::GABc|]") }

      it "ends a repeat on the completed bar" do
        expect(flow.bars(1).first.ends_repeat_after_num_plays).to eq 2
      end

      it "starts a repeat on the entered bar" do
        expect(flow.bars(2).last.starts_repeat?).to be true
      end
    end

    it "ignores a repeat ending before any voice events" do
      flow = parse_body(":|CDEF|")
      expect(flow.bars(1).first.ends_repeat?).to be false
    end

    it "sets no repeat flags for plain and section bar lines" do
      flow = parse_body("CDEF|GABc|]")
      bars = flow.bars(2)
      expect(bars.map(&:starts_repeat?) + bars.map(&:ends_repeat?)).to all(be false)
    end
  end

  describe "voltas" do
    context "with first and second endings" do
      subject(:flow) { parse_body("|:CDEF|1 GABc:|2 cdef|]") }

      let(:bars) { flow.bars(3) }

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
      subject(:flow) { parse_body("CDEF|1 GABc|cdef:|[2 gabc|]") }

      let(:bars) { flow.bars(4) }

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
      subject(:flow) { parse_body("CDEF|1,3 GABc:|") }

      it "carries the full pass list onto the bar" do
        expect(flow.bars(2).last.plays_on_passes).to eq [1, 3]
      end
    end

    context "when the tune ends inside a volta" do
      subject(:flow) { parse_body("CDEF|1 GABc:|2 cdef") }

      it "tags the final bar at end of input" do
        expect(flow.bars(3).last.plays_on_passes).to eq [2]
      end
    end
  end

  describe "slurs" do
    def slurs(body)
      parse_body(body).voices.first.spans.map(&:to_s)
    end

    it "reads a slur" do
      expect(slurs("(CDE) F|")).to eq ["slur from 1:1:000 to 1:3:000"]
    end

    it "reads a slur nested in another" do
      expect(slurs("((CD)E) F|")).to eq ["slur from 1:1:000 to 1:2:000", "slur from 1:1:000 to 1:3:000"]
    end

    it "pairs slurs by nesting, dropping one that spans a single note" do
      expect(slurs("(CD(E)F|G4)|")).to eq ["slur from 1:1:000 to 2:1:000"]
    end

    it "reads a dotted slur as a slur" do
      expect(slurs(".(CD) E F|")).to eq ["slur from 1:1:000 to 1:2:000"]
    end

    it "closes a slur on a note tied across a barline" do
      expect(slurs("C (D E F-|F) G z2|")).to eq ["slur from 1:2:000 to 1:4:000"]
    end

    it "reads a slur over a chord" do
      expect(slurs("([CE] D) E F|")).to eq ["slur from 1:1:000 to 1:2:000"]
    end

    it "keeps slurs in each voice apart" do
      flow = parse("X:1\nL:1/4\nM:4/4\nV:1\nV:2\nK:C\nV:1\n(CD) E F|\nV:2\nC (D E) F|\n")
      expect(flow.voices.map { |voice| voice.spans.map(&:to_s) })
        .to eq [["slur from 1:1:000 to 1:2:000"], ["slur from 1:2:000 to 1:3:000"]]
    end

    it "drops a slur that ends on a rest" do
      expect(slurs("(C D z) F|")).to eq []
    end

    it "drops an unmatched close and an unclosed open" do
      expect(slurs("C D) (E F|")).to eq []
    end
  end

  describe "unsupported features" do
    {
      "a quoted chord symbol" => ['"Am" C|', '"Am"'],
      "a grace note" => ["{g}A|", "{g}"],
      "a tuplet" => ["(3ABC|", "(3"],
      "an unrecognized decoration" => ["!bogus!A|", "!bogus!"],
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

  describe "decorations" do
    def voice_for(body)
      parse_body(body).voices.first
    end

    def first_event(body)
      voice_for(body).voice_events.first
    end

    it "reads the staccato shorthand and its bang form as articulations" do
      voice = voice_for(".C !staccato!D !wedge!E F|")
      expect(voice.voice_events.map { |event| event.articulations.map(&:name_key) })
        .to eq [["staccato"], ["staccato"], ["staccatissimo"], []]
    end

    it "reads T as a trill" do
      expect(first_event("TC4|").ornaments.map(&:name_key)).to eq ["trill"]
    end

    it "reads M as the lower mordent" do
      expect(first_event("MC4|").ornaments.map(&:name_key)).to eq ["mordent"]
    end

    it "reads P as the inverted mordent" do
      expect(first_event("PC4|").ornaments.map(&:name_key)).to eq ["inverted_mordent"]
    end

    it "reads a legacy plus decoration" do
      expect(first_event("+turn+C4|").ornaments.map(&:name_key)).to eq ["turn"]
    end

    it "gathers several markings on one note" do
      event = first_event("!accent!!tenuto!T!sfz!C4|")
      expect([event.articulations.map(&:name_key), event.ornaments.map(&:name_key), event.note_dynamic.name_key])
        .to eq [%w[accent tenuto], ["trill"], "sfz"]
    end

    it "marks a chord" do
      expect(first_event("!marcato![CEG]4|").articulations.map(&:name_key)).to eq ["marcato"]
    end

    it "keeps a note's markings across a broken rhythm" do
      voice = voice_for(".C>!accent!D C2|")
      expect(voice.voice_events.first(2).map { |event| event.articulations.map(&:name_key) })
        .to eq [["staccato"], ["accent"]]
    end

    it "reads a dynamic as a dynamic event on the voice at its note" do
      voice = voice_for("C !p!D !f!E F|")
      expect(voice.dynamic_events.map(&:to_h))
        .to eq [{"position" => "1:2:000", "level" => "p"}, {"position" => "1:3:000", "level" => "f"}]
    end

    it "reads a dynamic on a rest as a dynamic event at the rest" do
      expect(voice_for("C !p!z D2|").dynamic_at("1:2").name_key).to eq "p"
    end

    it "drops markings on a rest" do
      expect { voice_for("!trill!Hz4|") }.not_to raise_error
    end

    it "keeps the rest a rest when its markings are dropped" do
      expect(first_event(".z4|")).to be_rest
    end

    it "drops recognized decorations the catalogs do not hold" do
      event = first_event("!fermata!~H!upbow!C4|")
      expect([event.articulations, event.ornaments, event.note_dynamic]).to eq [[], [], nil]
    end

    it "lets a dropped decoration stand before a bar line" do
      expect(voice_for("C4!D.C.!|]").voice_events.length).to eq 1
    end

    it "marks a tied note once, keeping markings from its tied note" do
      event = first_event(".C2-!accent!C2|")
      expect(event.articulations.map(&:name_key)).to eq %w[accent staccato]
    end

    it "places a dynamic on a tied note where it is written" do
      voice = voice_for("C2-!p!C2|")
      expect(voice.dynamic_events.map(&:to_h)).to eq [{"position" => "1:3:000", "level" => "p"}]
    end

    it "keeps dynamics for each voice" do
      flow = parse("X:1\nL:1/4\nK:C\nV:1\n!p!C4|\nV:2\n!f!C,4|\n")
      expect(flow.voices.map { |voice| voice.dynamic_at("1:1").name_key }).to eq %w[p f]
    end

    it "raises when a marking precedes a bar line" do
      expect { parse_body("C4!p!|") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /followed by a note, chord, or rest.*line/)
    end

    it "raises when a marking precedes a tie" do
      expect { parse_body("C2T-C2|") }.to raise_error(HeadMusic::Notation::ABC::ParseError, /followed by a note/)
    end

    it "raises when a marking precedes a broken rhythm" do
      expect { parse_body("CT>D C2|") }.to raise_error(HeadMusic::Notation::ABC::ParseError, /followed by a note/)
    end

    it "raises when a marking precedes a volta" do
      expect { parse_body("C4|T[2 D4|]") }.to raise_error(HeadMusic::Notation::ABC::ParseError, /followed by a note/)
    end

    it "raises when a marking precedes a voice change" do
      expect { parse("X:1\nL:1/4\nK:C\nV:1\nC4T\nV:2\nC,4|\n") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /followed by a note/)
    end

    it "raises when a marking ends the tune" do
      expect { parse_body("C4!trill!") }.to raise_error(HeadMusic::Notation::ABC::ParseError, /followed by a note/)
    end

    it "raises for two dynamics at one position" do
      expect { parse_body("!p!!f!C4|") }.to raise_error(HeadMusic::Notation::ABC::ParseError, /line 5/)
    end

    it "raises for two note dynamics on one note" do
      expect { parse_body("!sfz!!fp!C4|") }.to raise_error(HeadMusic::Notation::ABC::ParseError, /only one/)
    end

    it "keeps a dotted bar line unsupported" do
      expect { parse_body("C4.|") }.to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /"\."/)
    end

    it "refuses a U: field that would redefine a shorthand" do
      expect { parse("X:1\nU:T=!fermata!\nK:C\nTC|\n") }
        .to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /"U"/)
    end
  end

  describe "chords" do
    subject(:flow) { parse(<<~ABC) }
      X:1
      T:Chorale Fragment
      M:4/4
      L:1/4
      K:C
      [CEG]2 [DFA]2 | [EGC']4 |]
    ABC

    let(:voice) { flow.voices.first }

    it "places each chord as one voice event holding the bracketed pitches" do
      expect(voice.voice_events.map { |voice_event| [voice_event.position.to_s, voice_event.pitches.map(&:to_s)] })
        .to eq [["1:1:000", %w[C4 E4 G4]], ["1:3:000", %w[D4 F4 A4]], ["2:1:000", %w[E4 G4 C5]]]
    end

    it "marks the voice events as chords" do
      expect(voice.voice_events).to all(be_chord)
    end

    it "applies the length after the bracket to the whole chord" do
      expect(voice.voice_events.map { |voice_event| voice_event.rhythmic_value.name })
        .to eq ["half", "half", "whole"]
    end

    it "parses a single-note bracket as an ordinary note voice event" do
      voice_event = parse_body("[C] D|").voices.first.voice_events.first
      expect([voice_event.note?, voice_event.chord?, voice_event.pitches.map(&:to_s)])
        .to eq [true, false, ["C4"]]
    end

    it "reads uniform per-note lengths as the chord's length" do
      voice_event = parse_body("[C2E2G2]|").voices.first.voice_events.first
      expect(voice_event.rhythmic_value.name).to eq "half"
    end

    it "multiplies uniform inner lengths with the outer length (ABC 2.1 sec. 4.17)" do
      inner_outer = parse_body("[C2E2G2]3|").voices.first.voice_events.first
      outer_only = parse_body("[CEG]6|").voices.first.voice_events.first
      expect(inner_outer.rhythmic_value).to eq outer_only.rhythmic_value
    end

    it "treats differently-spelled equal inner lengths as uniform" do
      voice_event = parse_body("[C4/2E2G2]|").voices.first.voice_events.first
      expect(voice_event.rhythmic_value.name).to eq "half"
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
      voice_event = parse_body("[Cc]|").voices.first.voice_events.first
      expect([voice_event.chord?, voice_event.pitches.map(&:to_s)]).to eq [true, %w[C4 C5]]
    end

    it "applies broken rhythm across two chords" do
      voice_events = parse_body("[CEG]>[DFA]|").voices.first.voice_events
      expect(voice_events.map { |voice_event| voice_event.rhythmic_value.name })
        .to eq ["dotted quarter", "eighth"]
    end

    it "keeps both sides of a broken rhythm as chords" do
      voice_events = parse_body("[CEG]>[DFA]|").voices.first.voice_events
      expect(voice_events).to all(be_chord)
    end

    it "still rejects an inline field next to a chord as unsupported, not a chord" do
      expect { parse_body("[CEG] [K:G] A|") }
        .to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /\[K:G\]/)
    end

    it "persists an accidental inside a chord for the rest of the bar" do
      voice_events = parse_body("[^FA] F|").voices.first.voice_events
      expect(voice_events.map { |voice_event| voice_event.pitches.map(&:to_s) })
        .to eq [%w[F♯4 A4], %w[F♯4]]
    end

    it "resets a chord accidental at the bar line" do
      voice_events = parse_body("[^FA] F|F|").voices.first.voice_events
      expect(voice_events.last.pitches.map(&:to_s)).to eq %w[F4]
    end
  end

  describe "beam breaks" do
    def voice_events(body, meter: "C")
      parse(<<~ABC).voices.first.voice_events.sort_by(&:position)
        X:1
        L:1/8
        M:#{meter}
        K:C
        #{body}
      ABC
    end

    def flags(body, meter: "C")
      voice_events(body, meter: meter).map(&:beam_break_before)
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

    it "fuses a tied pair into one voice event whose beam flag is nil" do
      expect(voice_events("C-C DD").length).to eq 3
    end

    it "carries the head's flag through a tie and breaks before a spaced note" do
      expect(flags("C-C DD")).to eq [nil, true, false]
    end

    it "keeps a broken-rhythm pair beamed and does not reset adjacency" do
      expect(flags("C>D EF")).to eq [nil, false, true, false]
    end
  end
end
