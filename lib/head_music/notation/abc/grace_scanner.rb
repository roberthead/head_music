# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Scans one group of grace notes, "{gf}" or the slashed "{/g}", from the
  # position of its opening brace. Each grace note is a note or a bracket
  # chord with its own length, any decorations before it, and a tie after it.
  #
  # Anything else inside the braces makes the whole group one unsupported
  # token, as a bracket chord does.
  class GraceScanner
    GraceItem = Data.define(:notes, :length, :tied, :decorations, :line)

    def initialize(scanner, line_number, column)
      @scanner = scanner
      @line_number = line_number
      @column = column
      @start_pos = scanner.pos
    end

    def token
      scanner.skip(/\{/)
      slashed = !scanner.skip(%r{/}).nil?
      items = collect_items
      return fallback_token unless items

      Token.new(type: :grace, line: line_number, column: column, notes: items, style: slashed ? :slashed : nil)
    end

    private

    attr_reader :scanner, :line_number, :column, :start_pos

    def collect_items
      items = []
      decorations = []
      until scanner.skip(/\}/)
        next if scanner.skip(/[ \t]+/)

        decoration = scan_decoration
        if decoration
          decorations << decoration
          next
        end

        item = scan_item(decorations)
        return nil unless item

        items << item
        decorations = []
      end
      items unless items.empty? || decorations.any?
    end

    def scan_decoration
      LineScanner::DECORATION_PATTERNS.each do |pattern|
        lexeme = scanner.check(pattern)
        next unless lexeme
        return nil unless DecorationMapper.classify(lexeme)

        return scanner.scan(pattern)
      end
      nil
    end

    def scan_item(decorations)
      notes, length = scan_notes
      return nil unless notes

      GraceItem.new(notes: notes, length: length, tied: !scanner.skip("-").nil?, decorations: decorations, line: line_number)
    end

    def scan_notes
      if scanner.scan(LineScanner::NOTE_PATTERN)
        note = ChordScanner::ChordNote.new(accidental: scanner[1], letter: scanner[2], octave_marks: scanner[3], length: "")
        return [[note], scanner[4]]
      end
      return unless scanner.check(ChordScanner::START_PATTERN)

      chord = ChordScanner.new(scanner, line_number, column).token
      [chord.notes, chord.length] if chord.type == :chord
    end

    def fallback_token
      ensure_terminated
      scanner.pos = start_pos
      Token.new(type: :unsupported, line: line_number, column: column, lexeme: scanner.scan(/\{[^}]*\}/))
    end

    def ensure_terminated
      return if scanner.string.index("}", start_pos)

      raise ParseError.new(
        'Unterminated grace notes; expected "}"',
        line_number: line_number,
        snippet: scanner.string[start_pos, BodyLexer::SNIPPET_LENGTH]
      )
    end
  end
end
