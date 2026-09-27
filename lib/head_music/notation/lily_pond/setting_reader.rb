# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads the \key, \time, and \clef commands among a context's music. With
  # no stream to change, as in a \new Dynamics, which only repeats the
  # staves' settings, a setting is read for its syntax alone.
  class SettingReader
    COMMANDS = %w[key time clef].freeze

    def initialize(cursor)
      @cursor = cursor
    end

    def read(stream = nil)
      command = cursor.advance
      case command.lexeme
      when "key" then read_key(command, stream)
      when "time" then read_time(command, stream)
      when "clef" then read_clef(command, stream)
      end
    end

    private

    attr_reader :cursor

    def read_key(command, stream)
      pitch_token = cursor.advance
      mode_token = cursor.advance
      located(command) do
        key_signature = KeyReader.key_signature(pitch_token, mode_token)
        stream&.change_key_signature(key_signature, command.line)
      end
    end

    def read_time(command, stream)
      meter_token = cursor.advance
      located(command) do
        meter = MeterReader.meter(meter_token)
        stream&.change_meter(meter, command.line)
      end
    end

    def read_clef(command, stream)
      token = cursor.advance
      raise cursor.error("\\clef expects a clef name", token || command) unless clef_name?(token)

      stream&.clef(token.lexeme)
    end

    def clef_name?(token)
      return false unless token

      %i[word string].include?(token.type) || (token.type == :note && token.duration.nil?)
    end

    # A key or meter reader rejects a token without knowing where in the
    # document it came from, so an error that carries no line is given the
    # line of the command that introduced it.
    def located(command)
      yield
    rescue ParseError => parse_error
      raise parse_error if parse_error.line_number

      raise cursor.error(parse_error.message, command)
    end
  end
end
