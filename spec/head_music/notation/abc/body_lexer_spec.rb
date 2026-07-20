require "spec_helper"

describe HeadMusic::Notation::ABC::BodyLexer do
  def tokens_for(body, start_line: 1)
    described_class.new(body, start_line: start_line).tokens
  end

  # Inter-note spacing now surfaces as an additive :beam_break token;
  # tests that only care about the music tokens filter it out.
  def music_tokens_for(body, start_line: 1)
    tokens_for(body, start_line: start_line).reject { |token| token.type == :beam_break }
  end

  describe "notes" do
    it "lexes a simple line into one token per note" do
      tokens = music_tokens_for("GABc dedB")
      expect(tokens.map(&:type)).to eq([:note] * 8)
    end

    it "preserves the case of note letters" do
      tokens = music_tokens_for("GABc dedB")
      expect(tokens.map(&:letter)).to eq(%w[G A B c d e d B])
    end

    it "captures sharp, octave mark, and length" do
      token = tokens_for("^c'2").first
      expect(token.to_h).to include(accidental: "^", letter: "c", octave_marks: "'", length: "2")
    end

    it "captures flat, comma octave mark, and slash length" do
      token = tokens_for("_B,/").first
      expect(token.to_h).to include(accidental: "_", letter: "B", octave_marks: ",", length: "/")
    end

    it "captures a natural with empty octave marks and length" do
      token = tokens_for("=e").first
      expect(token.to_h).to include(accidental: "=", letter: "e", octave_marks: "", length: "")
    end

    it "captures double accidentals" do
      tokens = music_tokens_for("^^F __G")
      expect(tokens.map(&:accidental)).to eq(["^^", "__"])
    end

    it "captures a compound fraction length" do
      expect(tokens_for("A3/2").first.length).to eq("3/2")
    end

    it "captures a double-slash length" do
      expect(tokens_for("G//").first.length).to eq("//")
    end

    it "leaves the accidental nil when absent" do
      expect(tokens_for("A").first.accidental).to be_nil
    end
  end

  describe "rests" do
    it "lexes z as a rest with an empty length" do
      token = tokens_for("z").first
      expect(token.to_h).to include(type: :rest, length: "")
    end

    it "captures rest lengths" do
      tokens = music_tokens_for("z2 z/ z/2")
      expect(tokens.map(&:length)).to eq(["2", "/", "/2"])
    end
  end

  describe "bar lines" do
    it "lexes every style" do
      tokens = tokens_for("A | B || C |] D |: E :| F ::")
      expect(tokens.select { |token| token.type == :bar_line }.map(&:style))
        .to eq(["|", "||", "|]", "|:", ":|", "::"])
    end

    it "lexes a thick-thin start bar line" do
      expect(tokens_for("[| A").first.to_h).to include(type: :bar_line, style: "[|")
    end

    it "normalizes :||: to the double repeat style" do
      expect(tokens_for(":||:").first.style).to eq("::")
    end

    it "normalizes :|: to the double repeat style" do
      expect(tokens_for(":|:").first.style).to eq("::")
    end

    it "prefers the longest match" do
      expect(tokens_for("|]").map(&:style)).to eq(["|]"])
    end
  end

  describe "voltas" do
    it "lexes a first ending" do
      token = tokens_for("[1").first
      expect(token.to_h).to include(type: :volta, passes: [1])
    end

    it "lexes a second ending followed by notes" do
      tokens = tokens_for("[2 AB")
      expect(tokens.map(&:type)).to eq([:volta, :note, :note])
    end

    it "lexes a comma list of passes" do
      expect(tokens_for("[1,3").first.passes).to eq([1, 3])
    end

    it "expands a range of passes" do
      expect(tokens_for("[1-3").first.passes).to eq([1, 2, 3])
    end

    it "lexes the |1 shorthand as a bar line then a volta" do
      tokens = tokens_for("|1")
      expect(tokens.map(&:type)).to eq([:bar_line, :volta])
    end

    it "assigns the pass number in the |1 shorthand" do
      expect(tokens_for("|1").last.passes).to eq([1])
    end

    it "lexes the :|2 shorthand as a repeat bar line then a volta" do
      tokens = tokens_for(":|2")
      expect(tokens.map { |token| [token.type, token.style || token.passes] })
        .to eq([[:bar_line, ":|"], [:volta, [2]]])
    end

    it "raises for duplicate passes" do
      expect { tokens_for("|1,1") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /unique.*line 1/)
    end

    it "raises for a range overlapping a listed pass" do
      expect { tokens_for("[1-3,2") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /unique/)
    end
  end

  describe "broken rhythm" do
    it "lexes > between notes" do
      tokens = tokens_for("A>B")
      expect(tokens.map(&:type)).to eq([:note, :broken_rhythm, :note])
    end

    it "stores the > direction" do
      expect(tokens_for("A>B")[1].direction).to eq(:>)
    end

    it "stores the < direction" do
      expect(tokens_for("c<d")[1].direction).to eq(:<)
    end

    it "lexes a doubled mark as unsupported" do
      expect(tokens_for("A>>B")[1].to_h).to include(type: :unsupported, lexeme: ">>")
    end

    it "lexes a doubled < mark as unsupported" do
      expect(tokens_for("c<<d")[1].to_h).to include(type: :unsupported, lexeme: "<<")
    end
  end

  describe "voice changes" do
    it "lexes a V: line as a voice change" do
      token = tokens_for("V:2\nGA").first
      expect(token.to_h).to include(type: :voice_change, voice_id: "2", line: 1)
    end

    it "trims the voice id" do
      expect(tokens_for("V: Tenor ").first.voice_id).to eq("Tenor")
    end
  end

  describe "comments" do
    it "strips a % comment to the end of the line" do
      tokens = tokens_for("GA %just two notes\nBc")
      expect(tokens.map(&:letter)).to eq(%w[G A B c])
    end

    it "does not treat % inside a quoted string as a comment" do
      tokens = tokens_for("\"G7%\" A")
      expect(tokens.map(&:type)).to eq([:unsupported, :note])
    end
  end

  describe "line continuation" do
    it "continues a line ending in a backslash" do
      tokens = tokens_for("GA\\\nBc")
      expect(tokens.map(&:letter)).to eq(%w[G A B c])
    end

    it "reports real line numbers after a continuation" do
      tokens = tokens_for("GA\\\nBc\nde")
      expect(tokens.map(&:line)).to eq([1, 1, 2, 2, 3, 3])
    end
  end

  describe "blank line termination" do
    it "stops lexing at a blank line" do
      tokens = tokens_for("GA\n\nBc")
      expect(tokens.map(&:letter)).to eq(%w[G A])
    end
  end

  describe "beam breaks" do
    it "does not emit a beam break between adjacent notes" do
      tokens = tokens_for("CC")
      expect(tokens.map(&:type)).to eq([:note, :note])
    end

    it "emits a beam break between two spaced notes" do
      tokens = tokens_for("C C")
      expect(tokens.map(&:type)).to eq([:note, :beam_break, :note])
    end

    it "emits exactly one beam break between two beamed groups" do
      tokens = tokens_for("CCC DDD")
      types = tokens.map(&:type)
      expect(types).to eq([:note, :note, :note, :beam_break, :note, :note, :note])
      expect(types.count(:beam_break)).to eq(1)
    end

    it "positions the beam break between the third and fourth notes" do
      tokens = tokens_for("CCC DDD")
      break_index = tokens.index { |token| token.type == :beam_break }
      expect(tokens[break_index - 1].to_h).to include(type: :note, letter: "C")
      expect(tokens[break_index + 1].to_h).to include(type: :note, letter: "D")
    end

    it "records the beam break's line and column" do
      token = tokens_for("C C")[1]
      expect(token.to_h).to include(type: :beam_break, line: 1, column: 3)
    end

    it "emits no beam break for trailing whitespace" do
      tokens = tokens_for("CC ")
      expect(tokens.map(&:type)).to eq([:note, :note])
    end

    it "emits no beam break for whitespace before a comment" do
      tokens = tokens_for("CC %tail")
      expect(tokens.map(&:type)).to eq([:note, :note])
    end

    it "emits no beam break for whitespace before a line continuation" do
      tokens = tokens_for("CC \\\nDD")
      expect(tokens.map(&:type)).to eq([:note, :note, :note, :note])
    end

    it "emits no beam break for whitespace after a bar line" do
      tokens = tokens_for("C| C")
      expect(tokens.map(&:type)).to eq([:note, :bar_line, :note])
    end
  end

  describe "line and column numbers" do
    it "reports 1-based columns" do
      tokens = music_tokens_for("GA Bc")
      expect(tokens.map(&:column)).to eq([1, 2, 4, 5])
    end

    it "offsets line numbers by start_line" do
      tokens = tokens_for("GA\nBc", start_line: 5)
      expect(tokens.map(&:line)).to eq([5, 5, 6, 6])
    end
  end

  describe "chords" do
    it "lexes a bracket group as one chord token" do
      token = tokens_for("[CEG]").first
      expect(token.type).to eq(:chord)
    end

    it "captures each inner note in bracket order" do
      token = tokens_for("[CEG]").first
      expect(token.notes.map(&:letter)).to eq %w[C E G]
    end

    it "captures inner accidentals" do
      token = tokens_for("[^FAc']").first
      expect(token.notes.map(&:accidental)).to eq ["^", nil, nil]
    end

    it "captures inner octave marks" do
      token = tokens_for("[^FAc']").first
      expect(token.notes.map(&:octave_marks)).to eq ["", "", "'"]
    end

    it "lexes a chord beginning with an accidental" do
      token = tokens_for("[^CEG]").first
      expect(token.notes.first.to_h).to include(accidental: "^", letter: "C")
    end

    it "captures the length after the closing bracket" do
      expect(tokens_for("[CEG]2").first.length).to eq("2")
    end

    it "captures a slash length after the closing bracket" do
      expect(tokens_for("[CEG]/").first.length).to eq("/")
    end

    it "leaves the length empty when absent" do
      expect(tokens_for("[CEG]").first.length).to eq("")
    end

    it "lexes a single-note bracket as a chord token with one note" do
      token = tokens_for("[C]").first
      expect([token.type, token.notes.map(&:letter)]).to eq [:chord, ["C"]]
    end

    describe "leading-bracket disambiguation" do
      it "lexes [| as a bar line" do
        expect(tokens_for("[| A").first.type).to eq(:bar_line)
      end

      it "lexes [1 as a volta" do
        expect(tokens_for("[1").first.type).to eq(:volta)
      end

      it "lexes [K:G] as an unsupported inline field" do
        expect(tokens_for("[K:G]").first.type).to eq(:unsupported)
      end

      it "lexes [CEG] as a chord" do
        expect(tokens_for("[CEG]").first.type).to eq(:chord)
      end
    end

    it "captures per-note lengths on each chord note" do
      notes = tokens_for("[C2E2G2]").first.notes
      expect(notes.map(&:length)).to eq(%w[2 2 2])
    end

    it "captures uneven per-note lengths for the parser to reject" do
      notes = tokens_for("[C2EG]").first.notes
      expect(notes.map(&:length)).to eq(["2", "", ""])
    end

    it "raises for an unterminated chord" do
      expect { tokens_for("[CEG") }.to raise_error(
        HeadMusic::Notation::ABC::ParseError,
        'Unterminated chord; expected "]" (line 1)'
      )
    end

    it "raises for an empty bracket pair" do
      expect { tokens_for("[]") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /"\[".*column 1.*line 1/)
    end

    it "lexes a bracket group containing a tie as unsupported" do
      token = tokens_for("[C-E]").first
      expect(token.to_h).to include(type: :unsupported, lexeme: "[C-E]")
    end
  end

  describe "ties" do
    it "lexes a hyphen between notes as a tie token" do
      tokens = tokens_for("A-B")
      expect(tokens.map(&:type)).to eq([:note, :tie, :note])
    end

    it "lexes each hyphen of a tie chain" do
      tokens = tokens_for("A-A-A")
      expect(tokens.map(&:type)).to eq([:note, :tie, :note, :tie, :note])
    end

    it "records the tie's line and column" do
      expect(tokens_for("A-B")[1].to_h).to include(type: :tie, line: 1, column: 2)
    end

    it "ties a chord to the following note" do
      tokens = tokens_for("[CEG]-c")
      expect(tokens.map(&:type)).to eq([:chord, :tie, :note])
    end
  end

  describe "unsupported features" do
    it "lexes a quoted chord symbol as unsupported" do
      expect(tokens_for("\"G7\"").first.lexeme).to eq("\"G7\"")
    end

    it "lexes grace notes as unsupported" do
      expect(tokens_for("{ab}c").first.to_h).to include(type: :unsupported, lexeme: "{ab}")
    end

    it "lexes slur marks as unsupported" do
      tokens = tokens_for("(AB)")
      expect(tokens.map(&:type)).to eq([:unsupported, :note, :note, :unsupported])
    end

    it "lexes a tuplet marker with its digit" do
      tokens = tokens_for("(3ABC")
      expect(tokens.first.to_h).to include(type: :unsupported, lexeme: "(3")
    end

    it "lexes a turn mark as unsupported" do
      expect(tokens_for("~A").first.lexeme).to eq("~")
    end

    it "lexes a staccato dot as unsupported" do
      expect(tokens_for(".A").first.lexeme).to eq(".")
    end

    it "lexes a bang decoration as unsupported" do
      expect(tokens_for("!trill!A").first.lexeme).to eq("!trill!")
    end

    it "lexes a multi-measure rest as unsupported" do
      expect(tokens_for("Z").first.to_h).to include(type: :unsupported, lexeme: "Z")
    end

    it "lexes an invisible rest as unsupported" do
      expect(tokens_for("x").first.to_h).to include(type: :unsupported, lexeme: "x")
    end

    it "lexes an inline field as unsupported" do
      expect(tokens_for("[K:D] A").first.to_h).to include(type: :unsupported, lexeme: "[K:D]")
    end

    it "lexes a lyrics line as unsupported" do
      token = tokens_for("GA\nw: la la").last
      expect(token.to_h).to include(type: :unsupported, line: 2)
    end

    it "includes the field label in a lyrics line lexeme" do
      expect(tokens_for("w: la la").first.lexeme).to start_with("w:")
    end
  end

  describe "errors" do
    it "raises ParseError on an unknown character" do
      expect { tokens_for("GA @B") }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /"@".*column 4.*line 1/)
    end

    it "reports the line number of the offending character" do
      expect { tokens_for("GA\nB&", start_line: 3) }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /"&".*line 4/)
    end

    it "raises ParseError for invalid encoding" do
      expect { described_class.new("GA\xFF".dup.force_encoding("UTF-8")) }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /encoding|UTF-8/i)
    end
  end
end
