# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Scans one bracket chord — "[CEG]2" — from the position of its opening
  # bracket.
  #
  # Non-note content inside the brackets (ties, rests, spaces, decorations)
  # makes the whole group one unsupported token, matching how those constructs
  # surface outside a chord.
  class ChordScanner
    # One note inside a bracket chord. Each note may carry its own length;
    # the parser enforces that they are uniform and multiplies the shared
    # inner length with any outer length on the token (ABC 2.1 sec. 4.17).
    ChordNote = Data.define(:accidental, :letter, :octave_marks, :length)

    # Matches a bracket whose first content is a note, distinguishing a chord
    # from the other things a "[" can open.
    START_PATTERN = /\[(\^\^|\^|__|_|=)?[A-Ga-g]/

    NOTE_PATTERN = %r{(\^\^|\^|__|_|=)?([A-Ga-g])([',]*)([\d/]*)}

    def initialize(scanner, line_number, column)
      @scanner = scanner
      @line_number = line_number
      @column = column
      @start_pos = scanner.pos
    end

    # The :chord token, or the :unsupported token the whole group falls back
    # to. Raises when the brackets never close.
    def token
      scanner.skip(/\[/)
      notes = collect_notes
      return fallback_token unless notes

      new_token(type: :chord, notes: notes, length: scanner.scan(%r{[\d/]*}))
    end

    private

    attr_reader :scanner, :line_number, :column, :start_pos

    # Collects the notes between the brackets, or nil when a non-note is hit
    # (leaving the scanner where it stopped so the fallback can react).
    def collect_notes
      notes = []
      until scanner.skip(/\]/)
        return nil unless scanner.scan(NOTE_PATTERN)

        notes << ChordNote.new(
          accidental: scanner[1], letter: scanner[2],
          octave_marks: scanner[3], length: scanner[4]
        )
      end
      notes
    end

    def fallback_token
      ensure_terminated
      scanner.pos = start_pos
      lexeme = scanner.scan(/\[[^\]]*\]/) || scanner.scan(/\[[^\]]*/)
      new_token(type: :unsupported, lexeme: lexeme)
    end

    def ensure_terminated
      return unless scanner.eos?

      raise ParseError.new(
        'Unterminated chord; expected "]"',
        line_number: line_number,
        snippet: scanner.string[start_pos, BodyLexer::SNIPPET_LENGTH]
      )
    end

    def new_token(**attributes)
      Token.new(line: line_number, column: column, **attributes)
    end
  end
end
