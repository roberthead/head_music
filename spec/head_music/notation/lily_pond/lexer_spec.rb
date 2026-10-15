require "spec_helper"

describe HeadMusic::Notation::LilyPond::Lexer do
  def tokens(source)
    described_class.new(source).tokens
  end

  def types(source)
    tokens(source).map(&:type)
  end

  def first_token(source)
    tokens(source).first
  end

  describe "notes" do
    it "lexes a bare letter" do
      token = first_token("c")
      expect([token.type, token.letter, token.suffix, token.octave_marks, token.duration]).to eq [:note, "c", nil, nil, nil]
    end

    it "lexes octave marks, suffix, and duration" do
      token = first_token("cis''4.")
      expect([token.letter, token.suffix, token.octave_marks, token.duration]).to eq ["c", "is", "''", "4."]
    end

    it "lexes downward octave marks" do
      expect(first_token("b,,").octave_marks).to eq ",,"
    end

    %w[is es isis eses].each do |suffix|
      it "lexes the #{suffix} suffix" do
        expect(first_token("c#{suffix}").suffix).to eq suffix
      end
    end

    %w[cih ceh cisih ceseh aih'4].each do |source|
      it "lexes the quarter-tone name #{source} as unsupported" do
        token = first_token(source)
        expect([token.type, token.lexeme]).to eq [:unsupported, source]
      end
    end

    {"as" => %w[a es], "ases" => %w[a eses], "es" => %w[e es], "eses" => %w[e eses], "aes" => %w[a es], "ees" => %w[e es]}.each do |source, (letter, suffix)|
      it "reads #{source} as #{letter} with the #{suffix} suffix" do
        token = first_token(source)
        expect([token.letter, token.suffix]).to eq [letter, suffix]
      end
    end

    it "lexes named long durations" do
      expect(first_token("c\\breve").duration).to eq "\\breve"
    end

    it "lexes a duration multiplier" do
      expect(first_token("c4*3/2").multiplier).to eq "3/2"
    end

    it "keeps the source lexeme" do
      expect(first_token("cis'8").lexeme).to eq "cis'8"
    end

    %w[bass treble alto tenor composer Staff Voice instrumentName title arranger].each do |word|
      it "does not mistake #{word} for a note" do
        expect(first_token(word).type).to eq :word
      end
    end
  end

  describe "rests" do
    it "lexes a rest with a duration" do
      token = first_token("r8")
      expect([token.type, token.duration]).to eq [:rest, "8"]
    end

    it "lexes a whole-bar rest with its multiplier" do
      token = first_token("R1*4/4")
      expect([token.type, token.duration, token.multiplier]).to eq [:whole_bar_rest, "1", "4/4"]
    end

    it "lexes a spacer rest with its duration" do
      token = first_token("s4.")
      expect([token.type, token.lexeme, token.duration]).to eq [:spacer, "s4.", "4."]
    end

    it "lexes a spacer rest with its multiplier" do
      token = first_token("s1*16")
      expect([token.type, token.duration, token.multiplier]).to eq [:spacer, "1", "16"]
    end

    it "lexes \\after with a dotted duration" do
      token = first_token("\\after 4. \\p")
      expect([token.type, token.lexeme, token.duration, token.multiplier]).to eq [:after, "\\after", "4.", nil]
    end

    it "lexes \\after with a multiplied duration" do
      token = first_token("\\after 4*3/5 \\p")
      expect([token.type, token.duration, token.multiplier]).to eq [:after, "4", "3/5"]
    end

    it "lexes \\after with no duration for the reader to refuse" do
      expect(tokens("\\after \\p").map { |token| [token.type, token.duration] }).to eq [[:after, nil], [:command, nil]]
    end

    it "does not mistake a longer command for \\after" do
      expect(first_token("\\afterGrace").type).to eq :command
    end

    it "lexes \\tuplet with its fraction" do
      token = first_token("\\tuplet 3/2 { c8 }")
      expect([token.type, token.lexeme, token.fraction, token.duration]).to eq [:tuplet, "\\tuplet", "3/2", nil]
    end

    it "lexes \\tuplet with a dotted span" do
      expect(tokens("\\tuplet 4/3 4. { c8 }").map(&:type)).to eq %i[tuplet open_brace note close_brace]
      expect(first_token("\\tuplet 4/3 4. { c8 }").duration).to eq "4."
    end

    it "leaves a note after \\tuplet's fraction to the note" do
      expect(tokens("\\tuplet 3/2 c4").map { |token| [token.type, token.duration] }).to eq [[:tuplet, nil], [:note, "4"]]
    end

    it "lexes \\times with its fraction and no span" do
      expect(tokens("\\times 2/3 4").map { |token| [token.type, token.fraction] }).to eq [[:tuplet, "2/3"], [:number, nil]]
    end

    it "lexes \\tuplet with no fraction for the reader to refuse" do
      expect(first_token("\\tuplet { c8 }").fraction).to be_nil
    end

    it "lexes \\tupletSpan with its duration, leaving \\default to the reader" do
      expect(tokens("\\tupletSpan 8*3 \\tupletSpan \\default").map { |token| [token.type, token.duration, token.multiplier] })
        .to eq [[:tuplet_span, "8", "3"], [:tuplet_span, nil, nil], [:command, nil, nil]]
    end

    it "does not mistake a word for a spacer" do
      expect(first_token("staff").type).to eq :word
    end

    it "does not mistake relative for a rest" do
      expect(first_token("relative").type).to eq :word
    end
  end

  describe "structure" do
    it "lexes braces, parallel brackets, bar checks, ties, and equals" do
      expect(types("{ << >> } | ~ =")).to eq %i[open_brace open_parallel close_parallel close_brace bar_check tie equals]
    end

    it "lexes chord brackets with the duration on the closer" do
      result = tokens("<c e g>4.")
      expect(result.map(&:type)).to eq %i[open_chord note note note close_chord]
      expect(result.last.duration).to eq "4."
    end

    it "lexes commands without their backslash" do
      token = first_token("\\relative")
      expect([token.type, token.lexeme]).to eq [:command, "relative"]
    end

    it "lexes a time signature as a number" do
      token = tokens("\\time 6/8").last
      expect([token.type, token.lexeme]).to eq [:number, "6/8"]
    end
  end

  describe "strings" do
    it "unescapes the body" do
      expect(first_token(%("The \\"Great\\" \\\\ Escape")).lexeme).to eq %(The "Great" \\ Escape)
    end

    it "keeps a percent sign inside a string" do
      expect(first_token(%("100% done")).lexeme).to eq "100% done"
    end

    it "raises for an unterminated string" do
      expect { tokens(%(title = "Air)) }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unterminated string.*line 1/)
    end
  end

  describe "comments and whitespace" do
    it "skips line comments" do
      expect(types("c4 % a comment\nd4")).to eq %i[note note]
    end

    it "skips block comments" do
      expect(types("c4 %{ a\nmulti-line\ncomment %} d4")).to eq %i[note note]
    end

    it "keeps line numbers true across block comments" do
      expect(tokens("c4 %{ a\nmulti-line\ncomment %} d4").last.line).to eq 3
    end

    it "keeps columns true after a block comment" do
      expect(tokens("c4 %{ a\nmulti-line\ncomment %} d4").last.column).to eq 12
    end

    it "raises for an unterminated block comment at its opening line" do
      expect { tokens("c4\n%{ never closed\nd4") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unterminated block comment.*line 2/)
    end

    it "lexes nothing for a comment-only document" do
      expect(tokens("% nothing here")).to be_empty
    end

    it "treats tabs and blank lines as insignificant" do
      expect(types("\tc4\n\n\n  d4  ")).to eq %i[note note]
    end
  end

  describe "positions" do
    it "numbers lines from one" do
      expect(tokens("c4\nd4\ne4").map(&:line)).to eq [1, 2, 3]
    end

    it "numbers columns from one in characters" do
      expect(tokens("  c4 d4").map(&:column)).to eq [3, 6]
    end

    it "counts multi-byte characters as one column" do
      expect(tokens(%("Dvořák" c4)).last.column).to eq 10
    end
  end

  describe "input normalization" do
    it "strips a leading byte-order mark" do
      expect(types("\uFEFFc4")).to eq [:note]
    end

    it "raises for invalid UTF-8" do
      expect { tokens("c4 \xFF".dup.force_encoding(Encoding::UTF_8)) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /not valid UTF-8/)
    end
  end

  describe "unsupported constructs" do
    {
      "\\\\" => "\\\\", "\\<" => "\\<", "\\>" => "\\>", "\\!" => "\\!", "#(display 1)" => "#(display", "##f" => "##f",
      "[" => "[", "]" => "]", "(" => "(", ")" => ")",
      "\\(" => "\\(", "\\)" => "\\)", "\\=1(" => "\\=1(", "\\=slur\\)" => "\\=slur\\)",
      "-." => "-.", "->" => "->", "--" => "--", "^" => "^", "_" => "_", ":" => ":", "!" => "!", "?" => "?"
    }.each do |source, lexeme|
      it "lexes #{source} as unsupported" do
        token = first_token(source)
        expect([token.type, token.lexeme]).to eq [:unsupported, lexeme]
      end
    end
  end

  describe "unexpected characters" do
    it "raises with the line and column" do
      expect { tokens("c4\nd4 @") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unexpected character "@" at column 4 \(line 2\)/)
    end

    it "raises for a dot with no duration number" do
      expect { tokens("d.") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unexpected character "\."/)
    end

    it "carries the line, column, and snippet" do
      expect { tokens("c4 @ d4") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError) { |error|
        expect([error.line_number, error.column, error.snippet]).to eq [1, 4, "@ d4"]
      }
    end

    it "names an invisible character by its escape" do
      expect { tokens("c4 \u0000") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unexpected character "\\u0000"/)
    end
  end
end
