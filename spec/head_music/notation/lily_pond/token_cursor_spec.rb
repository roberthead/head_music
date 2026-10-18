require "spec_helper"

describe HeadMusic::Notation::LilyPond::TokenCursor do
  def cursor_for(source)
    described_class.new(HeadMusic::Notation::LilyPond::Lexer.new(source).tokens)
  end

  describe "#accept" do
    it "consumes a token of the type given" do
      cursor = cursor_for("~ c'")
      expect([cursor.accept(:tie)&.type, cursor.peek.type]).to eq %i[tie note]
    end

    it "leaves a token of another type" do
      cursor = cursor_for("c'")
      expect([cursor.accept(:tie), cursor.peek.type]).to eq [nil, :note]
    end

    it "answers nil at the end" do
      expect(cursor_for("").accept(:tie)).to be_nil
    end
  end

  describe "#unexpected" do
    it "reports a command as an unsupported feature" do
      cursor = cursor_for("\\transpose")
      error = cursor.unexpected(cursor.peek, "Expected music")
      expect([error.class, error.message]).to match [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /"\\transpose"/]
    end

    it "reports an unsupported token as an unsupported feature" do
      cursor = cursor_for("-1")
      expect(cursor.unexpected(cursor.peek, "Expected music")).to be_a(HeadMusic::Notation::LilyPond::UnsupportedFeatureError)
    end

    it "reports anything else with the message given" do
      cursor = cursor_for("c'")
      error = cursor.unexpected(cursor.peek, "Expected music")
      expect([error.class, error.message]).to match [HeadMusic::Notation::LilyPond::ParseError, /Expected music/]
    end

    it "reports the end of the music at the last token" do
      cursor = cursor_for("c'")
      cursor.advance
      expect(cursor.unexpected(nil, "Expected music").line_number).to eq 1
    end
  end
end
