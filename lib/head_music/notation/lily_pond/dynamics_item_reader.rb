# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads the items of a \new Dynamics. The context only marks time, so a rest
  # there is a spacer and anything that sounds is refused. Bar marks repeat the
  # staves' and are read for their syntax alone. Its braces are read by the
  # MusicReader that calls this one.
  class DynamicsItemReader
    def initialize(cursor, music, items, settings:, bar_marks:)
      @cursor = cursor
      @music = music
      @items = items
      @settings = settings
      @bar_marks = bar_marks
    end

    def read(context)
      token = cursor.peek
      case token.type
      when :spacer, :rest, :whole_bar_rest then items.read_spacer(context)
      when :bar_check then items.read_bar_check(context)
      when :open_brace then music.read_expression(context)
      when :note, :open_chord then raise cursor.unsupported("Notes inside \\new Dynamics are not supported", token)
      when :command then read_command(token)
      when :unsupported then raise cursor.unsupported_token(token)
      else raise cursor.error(%(Unexpected token "#{token.lexeme}" inside \\new Dynamics), token)
      end
    end

    private

    attr_reader :cursor, :music, :items, :settings, :bar_marks

    def read_command(token)
      case token.lexeme
      when *SettingReader::COMMANDS then settings.read
      when *BarMarkReader::COMMANDS then bar_marks.read
      else raise cursor.unsupported_command(token)
      end
    end
  end
end
