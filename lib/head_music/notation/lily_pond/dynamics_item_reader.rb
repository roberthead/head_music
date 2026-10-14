# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads the items of a \new Dynamics. The context only marks time, so a rest
  # there is a spacer, a <> carries marks, and anything that sounds is
  # refused. Bar marks repeat the
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
      when :open_chord then items.marker? ? items.read_marker(context) : raise(notes_unsupported(token))
      when :note then raise notes_unsupported(token)
      when :command then read_command(token)
      when :unsupported then raise cursor.unsupported_token(token)
      else raise cursor.error(%(Unexpected token "#{token.lexeme}" inside \\new Dynamics), token)
      end
    end

    private

    attr_reader :cursor, :music, :items, :settings, :bar_marks

    def notes_unsupported(token)
      cursor.unsupported("Notes inside \\new Dynamics are not supported", token)
    end

    def read_command(token)
      case token.lexeme
      when *SettingReader::COMMANDS then settings.read
      when *BarMarkReader::COMMANDS then bar_marks.read
      when *MarkReader::HAIRPIN_STYLE_COMMANDS then cursor.advance
      else raise cursor.unsupported_command(token)
      end
    end
  end
end
