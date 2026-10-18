require "spec_helper"

describe HeadMusic::Notation::LilyPond::Token do
  def token(type, lexeme)
    described_class.new(type: type, line: 1, column: 1, lexeme: lexeme)
  end

  describe "#is?" do
    it "matches a type and an exact lexeme" do
      expect(token(:command, "default").is?(:command, "default")).to be true
    end

    it "matches a lexeme pattern" do
      expect(token(:unsupported, "-.").is?(:unsupported, /\A-/)).to be true
    end

    it "rejects another type with the same lexeme" do
      expect(token(:word, "default").is?(:command, "default")).to be false
    end

    it "rejects another lexeme" do
      expect(token(:command, "defaults").is?(:command, "default")).to be false
    end
  end
end
