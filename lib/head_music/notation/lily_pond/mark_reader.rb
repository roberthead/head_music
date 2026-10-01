# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads the marks written after a note, rest, or chord: articulation
  # shorthands such as -. and ->, and commands such as \trill, \sfz, and \p,
  # bare or after a direction sign. A mark the catalogs do not hold, such as a
  # fermata or a bowing, is consumed and dropped, so it cannot fail a file
  # that imports today. Anything else ends the run of marks and is left for
  # the reader, so fingerings and stray signs still raise.
  #
  # Slur and phrasing-slur marks are kept in the order written, each with
  # the name a \= gives it, for the placer to pair.
  class MarkReader
    SpanMark = Data.define(:kind, :opening, :id)

    Marks = Data.define(:articulations, :ornaments, :note_dynamic, :level, :span_marks) do
      def initialize(articulations: [], ornaments: [], note_dynamic: nil, level: nil, span_marks: [])
        super
      end

      # The links of a tied note are one note event, so their marks join.
      def merge(other)
        with(
          articulations: articulations | other.articulations,
          ornaments: ornaments | other.ornaments,
          note_dynamic: note_dynamic || other.note_dynamic,
          level: level || other.level,
          span_marks: span_marks + other.span_marks
        )
      end
    end

    NONE = Marks.new

    ARTICULATIONS_BY_SHORTHAND = {
      "." => "staccato", "!" => "staccatissimo", ">" => "accent", "-" => "tenuto", "^" => "marcato"
    }.freeze
    ORNAMENTS_BY_COMMAND = {
      "trill" => "trill", "mordent" => "mordent", "prall" => "inverted_mordent", "turn" => "turn"
    }.freeze
    ARTICULATION_COMMANDS = ARTICULATIONS_BY_SHORTHAND.values.freeze
    NOTE_DYNAMIC_COMMANDS = HeadMusic::Rudiment::Dynamic.accents.map(&:name_key).freeze
    LEVEL_COMMANDS = HeadMusic::Rudiment::Dynamic.levels.map(&:name_key).freeze
    DROPPED_COMMANDS = %w[
      fermata arpeggio upbow downbow breathe portato stopped sfp spp sff fz pppp ffff
      cresc decresc dim endcresc enddecresc enddim
    ].freeze
    DIRECTIONS = %w[- ^ _].freeze
    # The portato (_) and stopped (+) shorthands are read and dropped.
    SHORTHAND_PATTERN = /\A[-^_][.!>\-^_+]\z/
    # Hairpins are spans, which the model does not hold yet, so they are dropped.
    HAIRPIN_PATTERN = /\A\\[<>!]\z/
    SPAN_PATTERN = /\A(?:\\=([A-Za-z0-9]+))?(\\)?([()])\z/
    FIELD_NAMES = {note_dynamic: "sforzando", level: "dynamic level"}.freeze

    # Each command's [field, key], or nil for one that is dropped.
    MEANINGS_BY_COMMAND = {
      **ARTICULATION_COMMANDS.to_h { |key| [key, [:articulations, key]] },
      **ORNAMENTS_BY_COMMAND.transform_values { |key| [:ornaments, key] },
      **NOTE_DYNAMIC_COMMANDS.to_h { |key| [key, [:note_dynamic, key]] },
      **LEVEL_COMMANDS.to_h { |key| [key, [:level, key]] },
      **DROPPED_COMMANDS.to_h { |command| [command, nil] }
    }.freeze

    def initialize(cursor)
      @cursor = cursor
    end

    # Consumes every mark that follows, adding them to the marks given.
    def read(marks = NONE)
      count = mark_token_count
      while count
        tokens = Array.new(count) { cursor.advance }
        marks = add(marks, tokens.last)
        count = mark_token_count
      end
      marks
    end

    private

    attr_reader :cursor

    def mark_token_count
      token = cursor.peek
      return 1 if shorthand?(token) || hairpin?(token) || span?(token) || command?(token)

      following = cursor.peek(1)
      2 if direction?(token) && (command?(following) || hairpin?(following) || span?(following))
    end

    def shorthand?(token)
      token&.type == :unsupported && token.lexeme.match?(SHORTHAND_PATTERN)
    end

    def hairpin?(token)
      token&.type == :unsupported && token.lexeme.match?(HAIRPIN_PATTERN)
    end

    def span?(token)
      token&.type == :unsupported && token.lexeme.match?(SPAN_PATTERN)
    end

    def command?(token)
      token&.type == :command && MEANINGS_BY_COMMAND.key?(token.lexeme)
    end

    def direction?(token)
      token&.type == :unsupported && DIRECTIONS.include?(token.lexeme)
    end

    def add(marks, token)
      return marks.with(span_marks: marks.span_marks + [span_mark(token)]) if span?(token)

      field, key = meaning(token)
      return marks unless field
      return marks.with(field => marks.public_send(field) | [key]) if %i[articulations ornaments].include?(field)
      raise cursor.error(%(A note can carry only one #{FIELD_NAMES.fetch(field)}), token) if marks.public_send(field)

      marks.with(field => key)
    end

    def span_mark(token)
      id, phrasing, bracket = token.lexeme.match(SPAN_PATTERN).captures
      SpanMark.new(kind: phrasing ? :phrase : :slur, opening: bracket == "(", id: id)
    end

    def meaning(token)
      return MEANINGS_BY_COMMAND[token.lexeme] if token.type == :command
      return if hairpin?(token)

      articulation = ARTICULATIONS_BY_SHORTHAND[token.lexeme[1]]
      articulation && [:articulations, articulation]
    end
  end
end
