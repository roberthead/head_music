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

    it "reports the line of a tie onto a different pitch" do
      expect { parse_compound("E3-D2 |]") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError) { |error| expect(error.line_number).to eq 5 }
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

    it "ends one slur and begins the next on a tied note" do
      expect(slurs("(A B-)(B C) D|")).to eq ["slur from 1:1:000 to 1:2:000", "slur from 1:2:000 to 1:4:000"]
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

  describe "barline styles" do
    def barlines(body)
      parse_body(body).bars.map(&:barline)
    end

    it "reads double, final, and dotted barlines on the bars they close" do
      expect(barlines("C4||D4|]E4.|F4|G4|")).to eq %i[double final dotted regular regular]
    end

    it "leaves a thick-thin barline regular" do
      expect(barlines("C4[|D4|")).to eq %i[regular regular]
    end

    it "implies the final barline on the last bar" do
      expect(barlines("C4|D4|]")).to eq %i[regular regular]
    end

    it "implies the final barline on a last bar the last note is tied into" do
      expect(parse_body("C4|D4-|D4|]").to_h["bars"]).to eq []
    end
  end

  describe "repeat play counts" do
    it "plays a repeat as many times as its highest ending names" do
      flow = parse_body("|:C4|1,2 D4:|3 E4|]")
      expect(flow.bars(2).last.ends_repeat_after_num_plays).to eq 3
    end

    it "raises every closing repeat of the section" do
      flow = parse_body("|:C4|1 D4:|2 E4:|3 F4|]")
      expect(flow.bars(3).map(&:ends_repeat_after_num_plays)).to eq [nil, 3, 3]
    end

    it "keeps each section's count its own" do
      flow = parse_body("|:C4|1,2 D4:|3 E4||F4:|G4|]")
      expect(flow.bars(5).map(&:ends_repeat_after_num_plays)).to eq [nil, 3, nil, 2, nil]
    end
  end

  describe "part labels" do
    it "marks the bar a P: line opens" do
      flow = parse_body("P:A\nC4|D4|\nP:B\nE4|F4|]")
      expect(flow.bars.map(&:rehearsal_mark)).to eq ["A", nil, "B", nil]
    end

    it "marks the bar an inline [P:] field opens" do
      flow = parse_body("C4|[P:Verse]D4|]")
      expect(flow.bars.map(&:rehearsal_mark)).to eq [nil, "Verse"]
    end

    it "marks the first bar with a label before any voice" do
      flow = parse("X:1\nL:1/4\nK:C\nP:A\nV:1\nC4|D4|]\n")
      expect(flow.bars(1).last.rehearsal_mark).to eq "A"
    end

    it "ignores an empty label" do
      expect(parse_body("[P:]C4|]").bars(1).last.rehearsal_mark).to be_nil
    end

    it "drops a label after the music, which opens no bar" do
      flow = parse_body("C4|D4|\nP:B\n")
      expect(flow.to_h["bars"]).to eq []
    end

    it "reads a P: header, the playing order, and ignores it" do
      flow = parse("X:1\nP:AABA\nL:1/4\nK:C\nC4|]\n")
      expect(flow.bars.map(&:to_h)).to eq [{}]
    end
  end

  describe "navigation" do
    def marked_bars(body)
      parse_body(body).bars.map(&:to_h).map { |hash| hash.except("barline") }
    end

    it "marks a segno and coda sign before a note on that note's bar" do
      expect(marked_bars("C4|!segno!D4|!coda!E4|]")).to eq [{}, {"segno" => true}, {"coda" => true}]
    end

    it "marks a segno and coda sign before a bar line on the bar it opens" do
      expect(marked_bars("C4!segno!|D4!coda!|E4|]")).to eq [{}, {"segno" => true}, {"coda" => true}]
    end

    it "reads the S and O shorthands as segno and coda" do
      expect(marked_bars("SC4|OD4|]")).to eq [{"segno" => true}, {"coda" => true}]
    end

    it "marks a Fine, To Coda, and jump before a bar line on the bar it closes" do
      expect(marked_bars("C4!fine!|D4!dacoda!|E4!D.C.!|F4|]"))
        .to eq [{"fine" => true}, {"to_coda" => true}, {"jump" => {"kind" => "da_capo"}}, {}]
    end

    it "marks a jump at the end of the tune on the last bar" do
      expect(marked_bars("C4|D4!D.S.!")).to eq [{}, {"jump" => {"kind" => "dal_segno"}}]
    end

    it "drops a segno at the end of the tune, which opens no bar" do
      expect(marked_bars("C4|D4!segno!")).to eq [{}, {}]
    end

    it "drops a segno or coda sign before the final bar line, which opens no bar" do
      flow = parse_body("C4|D4!segno!!coda!|]")
      expect(flow.performance_order.map(&:number)).to eq [1, 2]
    end

    {
      "!dacapo!" => {"kind" => "da_capo"},
      "!D.C.alfine!" => {"kind" => "da_capo", "to" => "fine"},
      "!D.C.alcoda!" => {"kind" => "da_capo", "to" => "coda"},
      "!D.S.alfine!" => {"kind" => "dal_segno", "to" => "fine"},
      "!D.S.alcoda!" => {"kind" => "dal_segno", "to" => "coda"}
    }.each do |lexeme, jump|
      it "reads #{lexeme} as a jump" do
        expect(marked_bars("C4#{lexeme}|]")).to eq [{"jump" => jump}]
      end
    end

    it "reads the first of two coda signs as the To Coda when there is no !dacoda!" do
      expect(marked_bars("!segno!C4!coda!|D4!D.S.alcoda!|!coda!E4|]"))
        .to eq [{"segno" => true, "to_coda" => true}, {"jump" => {"kind" => "dal_segno", "to" => "coda"}}, {"coda" => true}]
    end

    it "keeps two coda signs when no al Coda jump needs a To Coda" do
      expect(marked_bars("C4!coda!|D4|!coda!E4|]")).to eq [{}, {"coda" => true}, {"coda" => true}]
    end

    it "keeps two coda signs when a !dacoda! marks the To Coda" do
      expect(marked_bars("!coda!C4!dacoda!|!coda!D4|]")).to eq [{"coda" => true, "to_coda" => true}, {"coda" => true}]
    end

    it "marks navigation before a volta like navigation before a bar line" do
      expect(marked_bars("C4|1 D4:|!fine!!coda![2 E4|]").map { |hash| hash.slice("fine", "coda") })
        .to eq [{}, {"fine" => true}, {"coda" => true}]
    end

    it "marks navigation before a voice change on the bar it closes" do
      flow = parse("X:1\nL:1/4\nK:C\nV:1\nC4!fine!\nV:2\nC,4|]\n")
      expect(flow.bars(1).last.fine?).to be true
    end

    it "plays the marked bars in order" do
      flow = parse_body("C4|!segno!D4|E4!dacoda!|F4!D.S.alcoda!||!coda!G4|]")
      expect(flow.performance_order.map(&:number)).to eq [1, 2, 3, 4, 2, 3, 5]
    end
  end

  describe "tuplets" do
    def tune(body, meter: "4/4", unit: "1/8")
      parse("X:1\nM:#{meter}\nL:#{unit}\nK:C\n#{body}\n").voices.first
    end

    def events(voice)
      voice.voice_events.map(&:to_s)
    end

    def groups(voice)
      voice.tuplets.map { |group| [group.to_s, group.unit.to_s] }
    end

    it "reads (3 as three notes in the time of two, and groups them" do
      voice = tune("(3CDE F2 G2 A2|")
      expect([events(voice).first(4), groups(voice)]).to eq [
        ["triplet eighth C4 at 1:1:000", "triplet eighth D4 at 1:1:320", "triplet eighth E4 at 1:1:640", "quarter F4 at 1:2:000"],
        [["3:2 tuplet from 1:1:000 to 1:2:000", "eighth"]]
      ]
    end

    it "reads triplet quarters over a half" do
      expect(groups(tune("(3C2D2E2 F4|"))).to eq [["3:2 tuplet from 1:1:000 to 1:3:000", "quarter"]]
    end

    it "reads an r fewer than p, as a quarter and an eighth under 3:2" do
      voice = tune("(3:2:2C2D (3:2:2zE2 F4|")
      expect([events(voice).first(4), groups(voice)]).to eq [
        ["triplet quarter C4 at 1:1:000", "triplet eighth D4 at 1:1:640", "triplet eighth rest at 1:2:000", "triplet quarter E4 at 1:2:320"],
        [["3:2 tuplet from 1:1:000 to 1:2:000", "eighth"], ["3:2 tuplet from 1:2:000 to 1:3:000", "eighth"]]
      ]
    end

    {"4/4" => "5:2 tuplet from 1:1:000 to 1:2:000", "6/8" => "5:3 tuplet from 1:1:000 to 1:4:000"}.each do |meter, group|
      it "reads (5 in #{meter} by the meter's default q" do
        rest = (meter == "4/4") ? "z6" : "z3"
        expect(groups(tune("(5CDEFG #{rest}|", meter: meter)).map(&:first)).to eq [group]
      end
    end

    it "reads (6 as 6:2, as ABC 2.1 does, and (6:4 as a sextuplet" do
      expect(groups(tune("(6CDEFGA z6|(6:4C/D/E/F/G/A/ z6|")).map(&:first))
        .to eq ["6:2 tuplet from 1:1:000 to 1:2:000", "6:4 tuplet from 2:1:000 to 2:2:000"]
    end

    it "rounds a septuplet's onsets from its start, and ends it exactly" do
      voice = tune("(7:4CDEFGAB z6|", unit: "1/16")
      expect([voice.voice_events.map { |voice_event| voice_event.position.to_s }, groups(voice), voice.first_gap]).to eq [
        %w[1:1:000 1:1:137:034 1:1:274:069 1:1:411:103 1:1:548:137 1:1:685:171 1:1:822:206 1:2:000],
        [["7:4 tuplet from 1:1:000 to 1:2:000", "sixteenth"]], nil
      ]
    end

    it "keeps back-to-back septuplet brackets that each hold part of a beat" do
      voice = tune("(7:4:3CDE (7:4:7CDEFGAB (7:4:4CDEF z8|", unit: "1/16")
      expect([groups(voice).map(&:first), voice.first_gap]).to eq [
        ["7:4 tuplet from 1:1:000 to 1:1:411:103", "7:4 tuplet from 1:1:411:103 to 1:2:411:103", "7:4 tuplet from 1:2:411:103 to 1:3:000"],
        nil
      ]
    end

    it "counts a chord once, and a rest and an invisible rest, but not decorations, slurs, or spacers" do
      voice = tune("(5:4:5!p!(C y[CE]z x).D z6|", unit: "1/16")
      expect([events(voice).first(5).map { |event| event.split(" at ").first }, groups(voice).map(&:first)]).to eq [
        ["5:4 sixteenth C4", "5:4 sixteenth C4 E4", "5:4 sixteenth rest", "5:4 sixteenth rest", "5:4 sixteenth D4"],
        ["5:4 tuplet from 1:1:000 to 1:2:000"]
      ]
    end

    it "keeps the ratio apart from a broken rhythm's dot" do
      expect(events(tune("(3C>DE F2 G2 A2|")).first(3))
        .to eq ["triplet dotted eighth C4 at 1:1:000", "triplet sixteenth D4 at 1:1:480", "triplet eighth E4 at 1:1:640"]
    end

    it "continues the count across a bar line" do
      expect(groups(tune("C6 (3c2d2|e2 C6|"))).to eq [["3:2 tuplet from 1:4:000 to 2:2:000", "quarter"]]
    end

    it "ends a group on the first link of a note tied out of it" do
      voice = tune("(3CDE-E2 F4|")
      expect([events(voice)[2], groups(voice).map(&:first)])
        .to eq ["triplet eighth tied to quarter E4 at 1:1:640", ["3:2 tuplet from 1:1:000 to 1:2:000"]]
    end

    it "starts a group on the later link of a note tied into it" do
      voice = tune("C2-(3CDE F4|")
      expect([events(voice).first, groups(voice).map(&:first)])
        .to eq ["quarter tied to triplet eighth C4 at 1:1:000", ["3:2 tuplet from 1:2:000 to 1:3:000"]]
    end

    it "keeps the ratios but drops the group of a tuplet the tune ends inside" do
      voice = tune("C6 (3cd|")
      expect([events(voice).last, groups(voice)]).to eq ["triplet eighth D5 at 1:4:320", []]
    end

    it "drops the group of a tuplet a voice change ends inside" do
      flow = parse("X:1\nM:4/4\nL:1/8\nK:C\nV:1\nC6 (3cd\nV:2\nC8|\nV:1\ne z2|\n")
      expect([flow.voices.first.voice_events.last(3).first(2).map(&:to_s), flow.voices.first.tuplets])
        .to eq [["triplet eighth D5 at 1:4:320", "eighth E5 at 1:4:640"], []]
    end

    it "reads a marker that changes no length, as (3:3, as plain notes" do
      voice = tune("(3:3CDE F2 G2 z|")
      expect([events(voice).first, groups(voice)]).to eq ["eighth C4 at 1:1:000", []]
    end

    it "refuses a tuplet inside a tuplet" do
      expect { tune("(3C(3DEF G4|") }
        .to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /nested tuplets.*line 5/)
    end

    it "refuses a tuplet in a voice overlay" do
      expect { tune("C8 & (3xxx x6|") }
        .to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /overlay holding notes or rests/)
    end

    {"(10" => "(10CDEFGABcde|", "(0:2" => "(0:2CD|"}.each do |lexeme, body|
      it "raises for #{lexeme}, which names no tuplet" do
        expect { tune(body) }.to raise_error(HeadMusic::Notation::ABC::ParseError) { |error| expect(error.snippet).to eq lexeme }
      end
    end
  end

  describe "grace notes" do
    def tune(body)
      parse("X:1\nM:4/4\nL:1/8\nK:C\n#{body}\n").voices.first
    end

    def graces(voice)
      voice.voice_events.reject { |voice_event| voice_event.grace_notes.empty? }.map do |voice_event|
        [voice_event.position.to_s, voice_event.grace_notes.map(&:to_s)]
      end
    end

    it "reads grace notes before the next note, their lengths relative to L:" do
      expect(graces(tune("{g}A2 {fe/}d2 c4|"))).to eq [
        ["1:1:000", ["grace eighth G5"]], ["1:2:000", ["grace eighth F5", "grace sixteenth E5"]]
      ]
    end

    it "reads {/...} as slashed grace notes" do
      expect(graces(tune("C2 {/a}B2 c4|"))).to eq [["1:2:000", ["slashed grace eighth A5"]]]
    end

    it "reads a grace chord" do
      expect(graces(tune("{[ce]2}c4 C4|"))).to eq [["1:1:000", ["grace quarter C5 E5"]]]
    end

    it "takes no time" do
      expect(tune("C2 {gab}c2 d4|").voice_events.map(&:to_s)).to eq ["quarter C4 at 1:1:000", "quarter C5 at 1:2:000", "half D5 at 1:3:000"]
    end

    it "keeps a grace note's articulation and tie, and puts a level on it at its main note" do
      voice = tune("C2 {.!p!!trill!B,-}B,2 C4|")
      grace = voice.voice_events[1].grace_notes.first
      expect([grace.articulations.map(&:name_key), grace.tied?, voice.dynamic_events.map(&:to_h)])
        .to eq [["staccato"], true, [{"position" => "1:2:000", "level" => "p"}]]
    end

    it "starts a slur opened before them on the first grace note" do
      expect(tune("({g}A2) ({/a}B2 c2) z2|").spans.map(&:to_s))
        .to eq ["slur from the grace notes before 1:1:000 to 1:1:000", "slur from the grace notes before 1:2:000 to 1:3:000"]
    end

    it "starts a slur opened after them on the main note" do
      expect(tune("{g}(A2 B2) c4|").spans.map(&:to_s)).to eq ["slur from 1:1:000 to 1:2:000"]
    end

    it "lets their accidentals hold for the rest of the bar" do
      expect(tune("{^f}f2 f2 z4|").voice_events.first(2).map(&:to_s)).to eq ["quarter F♯5 at 1:1:000", "quarter F♯5 at 1:2:000"]
    end

    {
      "a rest" => "{g}z2 A2 B4|",
      "a bar line" => "C6 {g}|A2 B6|",
      "an open tie's later link" => "A2-{g}A2 B4|",
      "the end of the tune" => "A8|{g}"
    }.each do |where, body|
      it "drops grace notes before #{where}" do
        expect(graces(tune(body))).to eq []
      end
    end

    {
      "within a bar" => ["z2 {B}C2-C4 z2|", "1:2:000"],
      "across a bar line" => ["z6 {B}C2-|C4 z4|", "1:4:000"]
    }.each do |where, (body, position)|
      it "keeps grace notes on a note tied #{where}" do
        expect(graces(tune(body))).to eq [[position, ["grace eighth B4"]]]
      end
    end

    it "starts a slur on the note after grace notes it drops" do
      expect(tune("({g}|A2 B2) c4|").spans.map(&:to_s)).to eq ["slur from 1:1:000 to 1:2:000"]
    end

    it "skips a grace note written as a tied value, which a grace note cannot hold" do
      expect(graces(tune("{g5a}A2 C6|"))).to eq [["1:1:000", ["grace eighth A5"]]]
    end

    it "does not count grace notes toward a tuplet" do
      expect(tune("(3{g}CDE F6|").tuplets.map(&:to_s)).to eq ["3:2 tuplet from 1:1:000 to 1:2:000"]
    end

    it "refuses grace notes in a voice overlay" do
      expect { tune("C8 & {g}x8|") }
        .to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /overlay holding notes or rests/)
    end
  end

  describe "unsupported features" do
    {
      "a quoted chord symbol" => ['"Am" C|', '"Am"'],
      "grace notes holding a slur" => ["{(gf)}A|", "{(gf)}"],
      "an unrecognized decoration" => ["!bogus!A|", "!bogus!"],
      "a double broken rhythm" => ["A>>B|", ">>"],
      "a multi-bar rest" => ["Z4|", "Z4"],
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
      expect { parse("X:1\nK:C\nCDEF|\nZ4|\n") }
        .to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /Z4.*line 4/)
    end

    it "raises before any interpretation when an unsupported token appears late in the body" do
      expect { parse_body("CDEF|GABc|Z4|") }
        .to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /Z4/)
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
      expect(voice_for("C4!upbow!|]").voice_events.length).to eq 1
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

    it "keeps a stray dot unsupported" do
      expect { parse_body("C4. D4|") }.to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /"\."/)
    end

    it "refuses a U: field that would redefine a shorthand" do
      expect { parse("X:1\nU:T=!fermata!\nK:C\nTC|\n") }
        .to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /"U"/)
    end
  end

  describe "fermatas" do
    def fermatas(body)
      parse_body(body).fermatas.map { |fermata| [fermata.from.to_s, fermata.to.to_s] }
    end

    {
      "H" => "C D HE F|", "!fermata!" => "C D !fermata!E F|", "+fermata+" => "C D +fermata+E F|",
      "!invertedfermata!" => "C D !invertedfermata!E F|", "a fermata on a rest" => "C D Hz F|",
      "a fermata on a chord" => "C D H[CEG] F|"
    }.each do |description, body|
      it "reads #{description} as a timeline fermata over the event" do
        expect(fermatas(body)).to eq [["1:3:000", "1:4:000"]]
      end
    end

    it "keeps the event's markings" do
      expect(parse_body("C D H.E F|").voices.first.voice_event_at("1:3").articulations.map(&:name_key)).to eq ["staccato"]
    end

    it "reads a fermata before a bar line as one on the event before it" do
      expect(fermatas("C D E F!fermata!|G4|")).to eq [["1:4:000", "2:1:000"]]
    end

    it "reads a fermata before the end of the tune as one on the last event" do
      expect(fermatas("C D E z H")).to eq [["1:4:000", "2:1:000"]]
    end

    it "drops a fermata with no event before it" do
      expect(fermatas("H|C4|")).to be_empty
    end

    it "starts a fermata on a tie's later link at that link" do
      expect(fermatas("C2 D2-|HD2 E2|")).to eq [["2:1:000", "2:3:000"]]
    end

    it "forms one fermata from marks in two voices, where they sound together" do
      flow = parse("X:1\nL:1/4\nK:C\nV:S\nc Hd e2|\nV:B\nC D/ HE/ F2|\n")
      expect(flow.fermatas.map { |fermata| [fermata.from.to_s, fermata.to.to_s] }).to eq [["1:2:480", "1:3:000"]]
    end
  end

  describe "tempo marks" do
    let(:flow) { parse_body(body) }

    def ramps
      flow.tempo_ramps.map { |ramp| [ramp.from.to_s, ramp.to.to_s, ramp.to_tempo&.beats_per_minute, ramp.text] }
    end

    context "with a Q: in the header" do
      let(:flow) { parse(%(X:1\nM:C|\nL:1/4\nQ:"Allegro" 1/2=80\nK:C\nC D E F|\n)) }

      it "opens at its tempo" do
        expect(flow.tempo_at(1)).to eq HeadMusic::Rudiment::Tempo.new("half", 80, text: "Allegro")
      end

      it "keeps the meter symbol" do
        expect(flow.meter.symbol).to eq :cut
      end
    end

    context "with an inline Q: at a downbeat" do
      let(:body) { "C D E F|[Q:1/4=80]G A B c|" }

      it "changes the tempo there" do
        expect(flow.tempo_changes).to eq(2 => HeadMusic::Rudiment::Tempo.new("quarter", 80))
      end
    end

    context "with a Q: line between lines of music" do
      let(:body) { "C D E F|\nQ:\"Adagio\"\nG A B c|" }

      it "changes the tempo where the music has reached" do
        expect(flow.tempo_at(2).text).to eq "Adagio"
      end
    end

    context "with a rit. annotation and a Q: at its end" do
      let(:body) { "C D \"^rit.\"E F|G A [Q:1/4=80]B c|" }

      it "reads a ramp to the tempo at its end" do
        expect(ramps).to eq [["1:3:000", "2:3:000", 80.0, "rit."]]
      end
    end

    context "with a rall. annotation and \"a tempo\"" do
      let(:body) { "C D \"_rall.\"E F|\"^a tempo\"G A B c|" }

      it "reads a ramp ending at the \"a tempo\"" do
        expect([ramps, flow.a_tempos.map { |a_tempo| a_tempo.position.to_s }]).to eq [[["1:3:000", "2:1:000", nil, "rall."]], ["2:1:000"]]
      end
    end

    context "with other annotation text" do
      let(:body) { "\"^dolce\"C D E F|" }

      it "drops it" do
        expect([flow.tempo_ramps, flow.a_tempos, flow.tempo_changes]).to all(be_empty)
      end
    end

    context "with an annotation in a voice overlay" do
      let(:body) { "C4 & x2 \"^rit.\"x2|D4|" }

      it "reads it where the overlay has reached" do
        expect(ramps).to eq [["1:3:000", "3:1:000", nil, "rit."]]
      end
    end

    context "with an empty inline Q:" do
      let(:body) { "C D E F|[Q:]G A B c|" }

      it "changes nothing" do
        expect(flow.tempo_changes).to be_empty
      end
    end

    context "with a Q: before any voice has begun" do
      let(:flow) { parse("X:1\nL:1/4\nK:C\n[Q:1/4=60]\nV:1\nC D E F|\n") }

      it "changes the tempo at the start of the music" do
        expect(flow.tempo_changes.keys).to eq [1]
      end
    end
  end

  describe "invisible rests and spacers" do
    def voice_for(body)
      parse_body(body).voices.first
    end

    def dynamics(voice)
      voice.dynamic_events.map(&:to_h)
    end

    it "places a level on an invisible rest after the last note, adding no event" do
      voice = voice_for("C D E !f!x|")
      expect([voice.voice_events.length, dynamics(voice)]).to eq [3, [{"position" => "1:4:000", "level" => "f"}]]
    end

    it "reads an invisible rest followed by a note as a rest" do
      voice = voice_for("!p!x C3|")
      expect(voice.voice_events.map(&:to_s)).to eq ["quarter rest at 1:1:000", "dotted half C4 at 1:2:000"]
    end

    it "keeps a level on an invisible rest followed by a note where the rest starts" do
      expect(dynamics(voice_for("C !p!x2 C|"))).to eq [{"position" => "1:2:000", "level" => "p"}]
    end

    it "places a level on a spacer where it stands" do
      voice = voice_for("C2 !f!y C2|")
      expect([voice.voice_events.length, dynamics(voice)]).to eq [2, [{"position" => "1:3:000", "level" => "f"}]]
    end

    it "places a level on a spacer between tied notes partway through the note" do
      voice = voice_for("C2-!p!y C2|")
      expect([voice.voice_events.map(&:to_s), dynamics(voice)])
        .to eq [["half tied to half C4 at 1:1:000"], [{"position" => "1:3:000", "level" => "p"}]]
    end

    it "places a tied note's level after the invisible rests before it" do
      expect(dynamics(voice_for("x2 C-!p!C|"))).to eq [{"position" => "1:4:000", "level" => "p"}]
    end

    it "drops markings on an invisible rest" do
      expect(voice_for("C2 !trill!x2|").voice_events.length).to eq 1
    end

    it "keeps invisible rests that reach a bar after the music's last as rests, so their level stays in written bars" do
      voice = voice_for("C3 x|!p!x4|")
      expect([voice.voice_events.map(&:to_s), dynamics(voice)]).to eq [
        ["dotted half C4 at 1:1:000", "quarter rest at 1:4:000", "whole rest at 2:1:000"],
        [{"position" => "2:1:000", "level" => "p"}]
      ]
    end

    it "draws no final barline on a bar holding only invisible rests" do
      expect(parse_body("C4|x4|]").last_marked_bar_number).to be_nil
    end
  end

  describe "voice overlays" do
    def voice_for(body)
      parse_body(body).voices.first
    end

    def dynamics(voice)
      voice.dynamic_events.map(&:to_h)
    end

    it "places a level inside a note, leaving the note whole" do
      voice = voice_for("c3 d & x !p!x3|")
      expect([voice.voice_events.map(&:to_s), dynamics(voice)])
        .to eq [["dotted half C5 at 1:1:000", "quarter D5 at 1:4:000"], [{"position" => "1:2:000", "level" => "p"}]]
    end

    it "places a level under a rest" do
      voice = voice_for("z4 & x2 !p!x2|")
      expect([voice.voice_events.map(&:to_s), dynamics(voice)])
        .to eq [["whole rest at 1:1:000"], [{"position" => "1:3:000", "level" => "p"}]]
    end

    it "places two levels in one note" do
      expect(dynamics(voice_for("C4 & x !p!x !f!x2|")))
        .to eq [{"position" => "1:2:000", "level" => "p"}, {"position" => "1:3:000", "level" => "f"}]
    end

    it "places a level on a spacer where the overlay stands" do
      expect(dynamics(voice_for("C4 & x2 !p!y x2|"))).to eq [{"position" => "1:3:000", "level" => "p"}]
    end

    it "starts the overlay at the start of its bar" do
      expect(dynamics(voice_for("C4| D4 & x !p!x3|"))).to eq [{"position" => "2:2:000", "level" => "p"}]
    end

    it "returns time to the music at the bar line" do
      expect(voice_for("C4 & x2 !p!x2| D4|").voice_events.map(&:to_s)).to eq ["whole C4 at 1:1:000", "whole D4 at 2:1:000"]
    end

    it "keeps a note tied across the bar line whole" do
      voice = voice_for("C4- & x2 !p!x2|C4 & x !f!x3|")
      expect([voice.voice_events.map(&:to_s), dynamics(voice)]).to eq [
        ["whole tied to whole C4 at 1:1:000"],
        [{"position" => "1:3:000", "level" => "p"}, {"position" => "2:2:000", "level" => "f"}]
      ]
    end

    {"a note" => "C4 & C4|", "a rest" => "C4 & z4|"}.each do |music, body|
      it "refuses an overlay holding #{music}, which would be a second voice" do
        expect { parse_body(body) }
          .to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /overlay holding notes or rests.*line 5/)
      end
    end

    it "refuses an overlay that runs past its bar's music" do
      expect { parse_body("C4 & x6 !p!x2|D4|") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /overlay must not run past its bar's music.*line 5/)
    end

    it "refuses a multi-bar overlay" do
      expect { parse_body("(&C4&)|") }.to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /"\(&"/)
    end
  end

  describe "hairpins" do
    def hairpins(abc_string)
      parse(abc_string).voices.map { |voice| voice.spans.map(&:to_s) }
    end

    {
      "a crescendo ending on a tie's later link" => ["!<(!C D E F-|!<)!F G A B|", ["crescendo from 1:1:000 to 2:1:000"]],
      "a start on a tied note and its end on the tie's later link" => ["!<(!C2-!<)!C2|", ["crescendo from 1:1:000 to 1:3:000"]],
      "an end before a tie, on the tie's later link" => ["!<(!C2!<)!-C2|", ["crescendo from 1:1:000 to 1:3:000"]],
      "a diminuendo inside a note, on an overlay" => ["C4 & x !>(!x !>)!x2|", ["diminuendo from 1:2:000 to 1:3:000"]],
      "an overlay end before its bar's start" => ["C2 !<)!D2 & !<(!x4|", ["crescendo from 1:1:000 to 1:3:000"]],
      "an end on a spacer at the final barline" => ["!<(!C D E F|G4 !<)!y|]", ["crescendo from 1:1:000 to 3:1:000"]],
      "an end on a spacer after a short bar's fill" => ["!<(!C D E x !<)!y|]", ["crescendo from 1:1:000 to 2:1:000"]],
      "an end before a bar line" => ["!<(!C D E F !<)!|", ["crescendo from 1:1:000 to 2:1:000"]],
      "an end before an overlay, where the bar's music ends" => ["!<(!C4 !<)!& x2 !p!x2|", ["crescendo from 1:1:000 to 2:1:000"]],
      "an end at the end of the tune" => ["!<(!C D E F!<)!", ["crescendo from 1:1:000 to 2:1:000"]],
      "a start and an end on rests" => ["!<(!z2 !<)!z2|", ["crescendo from 1:1:000 to 1:3:000"]],
      "an end on the note after a broken rhythm" => ["!<(!C!<)!>D C2|", ["crescendo from 1:1:000 to 1:2:480"]],
      "a level inside a hairpin" => ["!<(!C !f!D E !<)!F|", ["crescendo from 1:1:000 to 1:4:000"]],
      "a !crescendo(! closed by !<)!" => ["!crescendo(!C D !<)!E F|", ["crescendo from 1:1:000 to 1:3:000"]],
      "touching hairpins, the end written after the start" => ["!<(!C D !>(!!<)!E !>)!F|", [
        "crescendo from 1:1:000 to 1:3:000", "diminuendo from 1:3:000 to 1:4:000"
      ]],
      "touching crescendos, the start written before the end" => ["!<(!C D !<(!!<)!E F !<)!|", [
        "crescendo from 1:1:000 to 1:3:000", "crescendo from 1:3:000 to 2:1:000"
      ]],
      "an unterminated hairpin" => ["!<(!C D E F|", []],
      "a stray end" => ["C D !<)!E F|", []],
      "a mismatched end" => ["!<(!C D !>)!E F|", []],
      "a zero-length hairpin" => ["!<(!!<)!C D E F|", []],
      "a second start of a kind, which pairs with the end" => ["!<(!C !<(!D !<)!E F|", ["crescendo from 1:2:000 to 1:3:000"]],
      "a hairpin overlapping another" => ["!<(!C !>(!D !<)!E !>)!F|", ["crescendo from 1:1:000 to 1:3:000"]]
    }.each do |description, (body, expected)|
      it "reads #{description}" do
        expect(hairpins("X:1\nM:4/4\nL:1/4\nK:C\n#{body}\n")).to eq [expected]
      end
    end

    it "keeps a voice's hairpin open across another voice's music" do
      abc_string = "X:1\nL:1/4\nM:4/4\nV:1\nV:2\nK:C\nV:1\n!<(!C D E F|\nV:2\nC, D, E, F,|\nV:1\nG4 !<)!|\nV:2\nG,4|\n"
      expect(hairpins(abc_string)).to eq [["crescendo from 1:1:000 to 3:1:000"], []]
    end

    it "does not pair a mark with another voice's" do
      abc_string = "X:1\nL:1/4\nM:4/4\nV:1\nV:2\nK:C\nV:1\n!<(!C D E F|\nV:2\nC, D, E, !<)!F,|\n"
      expect(hairpins(abc_string)).to eq [[], []]
    end

    it "settles a mark before a voice change where its voice's time has reached" do
      abc_string = "X:1\nL:1/4\nM:4/4\nV:1\nV:2\nK:C\nV:1\n!>(!C D E F!>)!\nV:2\nC,4|\n"
      expect(hairpins(abc_string)).to eq [["diminuendo from 1:1:000 to 2:1:000"], []]
    end

    it "still reads !>! as an accent" do
      expect(parse_body("!>!C4|").voices.first.voice_events.first.articulations.map(&:name_key)).to eq ["accent"]
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
