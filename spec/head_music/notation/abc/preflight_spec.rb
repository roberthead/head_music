require "spec_helper"

describe HeadMusic::Notation::ABC::Preflight do
  describe ".ensure_input_present" do
    it "passes non-blank input" do
      expect { described_class.ensure_input_present("K:C\nCDEF|") }.not_to raise_error
    end

    it "raises on nil, empty, or whitespace-only input" do
      [nil, "", "   \n\t"].each do |blank|
        expect { described_class.ensure_input_present(blank) }
          .to raise_error(HeadMusic::Notation::ABC::ParseError, /blank/)
      end
    end
  end

  describe ".reject_content_after_tune" do
    def header_for(abc)
      HeadMusic::Notation::ABC::Header.new(abc, start_line: 1)
    end

    it "passes a single tune with no trailing content" do
      expect { described_class.reject_content_after_tune(header_for("X:1\nK:C\nCDEF|")) }
        .not_to raise_error
    end

    it "passes trailing blank lines and comment lines" do
      expect { described_class.reject_content_after_tune(header_for("X:1\nK:C\nCDEF|\n\n% a comment")) }
        .not_to raise_error
    end

    it "raises when a second tune follows a blank line" do
      expect { described_class.reject_content_after_tune(header_for("X:1\nK:C\nCDEF|\n\nX:2\nK:G\nGABc|")) }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /parse_book/)
    end
  end

  describe ".reject_unsupported_tokens" do
    def tokens_for(body)
      HeadMusic::Notation::ABC::BodyLexer.new(body, start_line: 1).tokens
    end

    it "passes a body of supported tokens" do
      expect { described_class.reject_unsupported_tokens(tokens_for("CDEF|")) }.not_to raise_error
    end

    it "raises on an unsupported token with its lexeme and line" do
      expect { described_class.reject_unsupported_tokens(tokens_for("C{g}D|")) }
        .to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /\{g\}/)
    end
  end
end
