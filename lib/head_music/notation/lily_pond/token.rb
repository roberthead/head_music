# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # One lexed unit of a LilyPond document.
  #
  # One struct type for all tokens keeps the reader's pattern matching
  # simple; fields that don't apply to a token type are nil. The lexeme is
  # the source text for commands, words, numbers, and unsupported marks,
  # and the unescaped body for strings.
  Token = Data.define(
    :type, :line, :column,
    :lexeme, :letter, :suffix, :octave_marks, :duration, :multiplier
  ) do
    def initialize(
      type:, line:, column:,
      lexeme: nil, letter: nil, suffix: nil, octave_marks: nil, duration: nil, multiplier: nil
    )
      super
    end
  end
end
