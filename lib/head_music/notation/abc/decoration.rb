# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # One decoration read from a tune, waiting for the note, chord, or rest it
  # decorates.
  Decoration = Data.define(:kind, :key, :line, :lexeme) do
    def self.from_token(token)
      lexeme = token.lexeme
      new(**DecorationMapper.classify(lexeme), line: token.line, lexeme: lexeme)
    end

    def level?
      kind == :level
    end

    def hairpin?
      %i[hairpin_start hairpin_end].include?(kind)
    end

    # Marks a moment rather than a note, so it can stand on an invisible rest
    # or a spacer.
    def positional?
      level? || hairpin?
    end

    def dropped?
      kind == :dropped
    end

    def navigation?
      kind == :navigation
    end
  end
end
