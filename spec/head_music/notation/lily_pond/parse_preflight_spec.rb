require "spec_helper"

describe HeadMusic::Notation::LilyPond::ParsePreflight do
  def tokens(source)
    HeadMusic::Notation::LilyPond::Lexer.new(source).tokens
  end

  describe ".ensure_input_present" do
    it "raises for nil" do
      expect { described_class.ensure_input_present(nil) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /blank/)
    end

    it "raises for whitespace" do
      expect { described_class.ensure_input_present(" \n\t") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /blank/)
    end

    it "passes for content" do
      expect { described_class.ensure_input_present("c4") }.not_to raise_error
    end
  end

  describe ".reject_unsupported_tokens" do
    it "raises an UnsupportedFeatureError naming the lexeme and line" do
      expect { described_class.reject_unsupported_tokens(tokens("c4\nd4-.")) }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Unsupported LilyPond feature "-\." \(line 2\)/)
    end

    it "passes when every token is supported" do
      expect { described_class.reject_unsupported_tokens(tokens("c4 d4 |")) }.not_to raise_error
    end
  end

  describe ".ensure_balanced_delimiters" do
    it "passes for nested braces, parallel brackets, and chords" do
      expect { described_class.ensure_balanced_delimiters(tokens("{ << { <c e>4 } >> }")) }.not_to raise_error
    end

    it "raises for an unclosed brace at its own line" do
      expect { described_class.ensure_balanced_delimiters(tokens("{\n{ c4 }\n")) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unclosed "\{" \(line 1\)/)
    end

    it "raises for a stray closer" do
      expect { described_class.ensure_balanced_delimiters(tokens("c4 }")) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unexpected "\}"/)
    end

    it "raises for a mismatched closer" do
      expect { described_class.ensure_balanced_delimiters(tokens("<< c4 }")) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unexpected "\}"/)
    end

    it "raises for an unclosed chord" do
      expect { described_class.ensure_balanced_delimiters(tokens("{ <c e }")) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unexpected "\}"/)
    end
  end
end
