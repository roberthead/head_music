# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads a grace command and the music after it: one note or chord, or a
  # braced run of them. Their pitches and durations go through the readers
  # the notes do, so a grace note sets the \relative reference and the
  # carried duration for what follows, even where it is then dropped.
  #
  # \appoggiatura and \acciaccatura imply a slur from the first grace note to
  # the main note, unless the first grace note opens one of its own.
  #
  # A \transposition among them holds from the grace note after it, or from
  # the main note when none follows.
  class GraceReader
    # Each command's [slashed, implied slur].
    COMMANDS_BY_NAME = {
      "grace" => [false, false], "slashedGrace" => [true, false],
      "appoggiatura" => [false, true], "acciaccatura" => [true, true]
    }.freeze
    COMMANDS = COMMANDS_BY_NAME.keys.freeze
    MUSIC_TYPES = %i[open_brace note open_chord].freeze

    def initialize(cursor, items)
      @cursor = cursor
      @items = items
      @mark_reader = MarkReader.new(cursor)
      @setting_reader = SettingReader.new(cursor)
    end

    # The grace notes the command at the cursor writes, or the music after a
    # command already read.
    def read(command = cursor.advance)
      @slashed, implied_slur = COMMANDS_BY_NAME.fetch(command.lexeme, [false, false])
      @graces = []
      @transposition = nil
      read_music(command)
      Graces.new(graces: @graces, implied_slur: implied_slur, transposition: @transposition)
    end

    private

    attr_reader :cursor, :items, :mark_reader, :setting_reader

    def read_music(command)
      token = cursor.peek
      raise cursor.error("\\#{command.lexeme} expects music", token || command) unless MUSIC_TYPES.include?(token&.type)

      read_item
    end

    def read_braces
      cursor.advance
      read_item until cursor.peek.type == :close_brace
      cursor.advance
    end

    def read_item
      token = cursor.peek
      case token.type
      when :note then read_grace
      when :open_chord then items.marker? ? raise(cursor.unsupported("A <> inside grace music is not supported", token)) : read_grace
      when :rest, :spacer then skip_silence
      when :open_brace then read_braces
      when :bar_check then cursor.advance
      when :tuplet then raise cursor.unsupported("Tuplets inside grace music are not supported", token)
      else
        return @transposition = setting_reader.read_transposition_step if token.type == :command && token.lexeme == "transposition"

        raise cursor.unexpected(token, %(Unexpected token "#{token.lexeme}" inside grace music))
      end
    end

    def read_grace
      pitches, rhythmic_value, _line, marks, tie = items.read_marked_sounds
      @graces << Graces::Grace.new(
        pitches: pitches, rhythmic_value: rhythmic_value, slashed: @slashed, tied: !tie.nil?, marks: marks, transposition: @transposition
      )
      @transposition = nil
    end

    def skip_silence
      items.carry_duration(cursor.advance)
      mark_reader.read
    end
  end
end
