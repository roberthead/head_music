require "spec_helper"

describe HeadMusic::Notation::LilyPond::MusicItemReader do
  def reader_for(source)
    cursor = HeadMusic::Notation::LilyPond::TokenCursor.new(HeadMusic::Notation::LilyPond::Lexer.new(source).tokens)
    described_class.new(cursor, HeadMusic::Notation::LilyPond::PitchReaderStack.new)
  end

  describe "#read_marked_sounds" do
    def read(source)
      pitches, rhythmic_value, line, marks, tie = reader_for(source).read_marked_sounds
      [pitches.map(&:to_s), rhythmic_value.to_s, line, marks.articulations, marks.level, tie&.type]
    end

    it "reads a note and the marks after it" do
      expect(read("c'4-.")).to eq [["C4"], "quarter", 1, ["staccato"], nil, nil]
    end

    it "reads marks on either side of a tie" do
      expect(read("c'4-.~\\p")).to eq [["C4"], "quarter", 1, ["staccato"], "p", :tie]
    end

    it "reads a chord" do
      expect(read("<c' e'>2")).to eq [["C4", "E4"], "half", 1, [], nil, nil]
    end
  end
end
