# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads the marks written after a note, rest, or chord: articulation
  # shorthands such as -. and ->, and commands such as \trill, \sfz, and \p,
  # bare or after a direction sign. A mark the catalogs do not hold, such as a
  # bowing, is consumed and dropped, so it cannot fail a file that imports
  # today. Anything else ends the run of marks and is left for the reader, so
  # fingerings and stray signs still raise.
  #
  # A fermata, of any length, is kept as a flag. Text after a direction sign,
  # a string or a markup's words, is kept for its tempo words.
  #
  # Slur and phrasing-slur marks are kept in the order written, each with
  # the name a \= gives it, for the placer to pair. So are hairpin marks:
  # :crescendo, :diminuendo, or :end, whether written \<, \cresc, or \!.
  # A span opened on a note's first grace note starts from_grace.
  class MarkReader
    SpanMark = Data.define(:kind, :opening, :id, :from_grace) do
      def initialize(kind:, opening:, id:, from_grace: false)
        super
      end

      def opens?(kind)
        opening && self.kind == kind
      end

      def on_grace
        opening ? with(from_grace: true) : self
      end
    end

    # Each fermata is true where it marks the start of the event, and the
    # rhythmic value before the tied link it marks otherwise.
    Marks = Data.define(:articulations, :ornaments, :note_dynamic, :level, :span_marks, :hairpin_marks, :fermatas, :texts) do
      def initialize(
        articulations: [], ornaments: [], note_dynamic: nil, level: nil, span_marks: [], hairpin_marks: [], fermatas: [], texts: []
      )
        super
      end

      # The links of a tied note are one note event, so their marks join.
      def merge(other)
        with(
          articulations: articulations | other.articulations,
          ornaments: ornaments | other.ornaments,
          note_dynamic: note_dynamic || other.note_dynamic,
          level: level || other.level,
          span_marks: span_marks + other.span_marks,
          hairpin_marks: hairpin_marks + other.hairpin_marks,
          fermatas: fermatas + other.fermatas,
          texts: texts + other.texts
        )
      end

      # What a tied note's later link holds where the link starts.
      def dynamics
        Marks.new(level: level, hairpin_marks: hairpin_marks, texts: texts)
      end

      # Levels, hairpins, and spans are placed on the voice instead.
      def mark(note_event)
        note_event.articulate(*articulations).embellish(*ornaments)
        note_event.note_dynamic = note_dynamic if note_dynamic
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
    FERMATA_COMMANDS = %w[
      fermata shortfermata longfermata verylongfermata veryshortfermata henzeshortfermata henzelongfermata
    ].freeze
    DROPPED_COMMANDS = %w[arpeggio upbow downbow breathe portato stopped sfp spp sff fz pppp ffff].freeze
    HAIRPINS_BY_LEXEME = {"\\<" => :crescendo, "\\>" => :diminuendo, "\\!" => :end}.freeze
    # The text forms draw "cresc." and "dim." where a hairpin would be.
    HAIRPINS_BY_COMMAND = {
      "cresc" => :crescendo, "dim" => :diminuendo, "decresc" => :diminuendo,
      "endcresc" => :end, "enddim" => :end, "enddecresc" => :end
    }.freeze
    # Commands that only choose how later hairpins are drawn.
    HAIRPIN_STYLE_COMMANDS = %w[crescTextCresc dimTextDim dimTextDecresc dimTextDecr crescHairpin dimHairpin].freeze
    DIRECTION_PATTERN = /\A[-^_]\z/
    # The portato (_) and stopped (+) shorthands are read and dropped.
    SHORTHAND_PATTERN = /\A[-^_][.!>\-^_+]\z/
    HAIRPIN_PATTERN = /\A\\[<>!]\z/
    SPAN_PATTERN = /\A(?:\\=([A-Za-z0-9]+))?(\\)?([()])\z/
    # The marks a direction sign may come before.
    DIRECTABLE_PATTERN = Regexp.union(HAIRPIN_PATTERN, SPAN_PATTERN)
    FIELD_NAMES = {note_dynamic: "sforzando", level: "dynamic level"}.freeze

    # Each command's [field, value], or nil for one that is dropped.
    MEANINGS_BY_COMMAND = {
      **ARTICULATION_COMMANDS.to_h { |key| [key, [:articulations, [key]]] },
      **ORNAMENTS_BY_COMMAND.transform_values { |key| [:ornaments, [key]] },
      **NOTE_DYNAMIC_COMMANDS.to_h { |key| [key, [:note_dynamic, key]] },
      **LEVEL_COMMANDS.to_h { |key| [key, [:level, key]] },
      **HAIRPINS_BY_COMMAND.transform_values { |mark| [:hairpin_marks, [mark]] },
      **FERMATA_COMMANDS.to_h { |command| [command, [:fermatas, [true]]] },
      **DROPPED_COMMANDS.to_h { |command| [command, nil] }
    }.freeze

    def initialize(cursor)
      @cursor = cursor
    end

    # Consumes every mark that follows, adding them to the marks given.
    def read(marks = NONE)
      marks = read_mark(marks) while mark_token_count
      marks
    end

    # Consumes the one mark a command such as \after takes.
    def read_one(command)
      raise cursor.unexpected(cursor.peek, "#{command} expects a mark") unless mark_token_count

      read_mark(NONE)
    end

    private

    attr_reader :cursor

    def read_mark(marks)
      cursor.advance if mark_token_count == 2
      return marks.merge(Marks.new(texts: [read_text])) if text?(cursor.peek)

      add(marks, cursor.advance)
    end

    def mark_token_count
      token = cursor.peek
      return 1 if token&.is?(:unsupported, SHORTHAND_PATTERN) || directable?(token)

      2 if token&.is?(:unsupported, DIRECTION_PATTERN) && (directable?(cursor.peek(1)) || text?(cursor.peek(1)))
    end

    def text?(token)
      token&.type == :string || token&.is?(:command, "markup")
    end

    def read_text
      (cursor.peek.type == :string) ? cursor.advance.lexeme : cursor.markup_text
    end

    def directable?(token)
      return false unless token

      token.is?(:unsupported, DIRECTABLE_PATTERN) || (token.type == :command && MEANINGS_BY_COMMAND.key?(token.lexeme))
    end

    def add(marks, token)
      field, value = meaning(token)
      return marks unless field

      name = FIELD_NAMES[field]
      raise cursor.error(%(A note can carry only one #{name}), token) if name && marks.public_send(field)

      marks.merge(Marks.new(field => value))
    end

    def meaning(token)
      lexeme = token.lexeme
      return MEANINGS_BY_COMMAND[lexeme] if token.type == :command
      return [:hairpin_marks, [HAIRPINS_BY_LEXEME.fetch(lexeme)]] if lexeme.match?(HAIRPIN_PATTERN)
      return [:span_marks, [span_mark(lexeme)]] if lexeme.match?(SPAN_PATTERN)

      articulation = ARTICULATIONS_BY_SHORTHAND[lexeme[1]]
      articulation && [:articulations, [articulation]]
    end

    def span_mark(lexeme)
      id, phrasing, bracket = lexeme.match(SPAN_PATTERN).captures
      SpanMark.new(kind: phrasing ? :phrase : :slur, opening: bracket == "(", id: id)
    end
  end
end
