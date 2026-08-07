# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # One lexed unit of a tune body.
  #
  # One struct type for all tokens keeps the parser's pattern matching
  # simple; fields that don't apply to a token type are nil.
  Token = Data.define(
    :type, :line, :column,
    :letter, :accidental, :octave_marks, :length,
    :style, :passes, :direction, :voice_id, :lexeme, :notes
  ) do
    def initialize(
      type:, line:, column:,
      letter: nil, accidental: nil, octave_marks: nil, length: nil,
      style: nil, passes: nil, direction: nil, voice_id: nil, lexeme: nil,
      notes: nil
    )
      super
    end
  end
end
