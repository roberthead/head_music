# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads the \key, \time, \clef, \tempo, and \transposition commands among a context's
  # music. With no stream to change, as in a \new Dynamics, which only
  # repeats the staves' settings, a setting is read for its syntax alone.
  #
  # LilyPond prints a plain \time 4/4 or 2/2 as common or cut time, so it
  # reads as one, until \numericTimeSignature asks for the numerals, and
  # again after \defaultTimeSignature.
  class SettingReader
    TIME_SIGNATURE_STYLES = {"numericTimeSignature" => true, "defaultTimeSignature" => false}.freeze
    COMMANDS = (%w[key time clef tempo transposition] + TIME_SIGNATURE_STYLES.keys).freeze
    SYMBOLS_BY_METER = {"4/4" => :common, "2/2" => :cut}.freeze

    def initialize(cursor)
      @cursor = cursor
      @tempo_reader = TempoReader.new(cursor)
    end

    def read(stream = nil)
      command = cursor.advance
      case command.lexeme
      when "key" then read_key(command, stream)
      when "time" then read_time(command, stream)
      when "clef" then read_clef(command, stream)
      when "tempo" then read_tempo(command, stream)
      when "transposition" then read_transposition(command, stream)
      else stream&.numeric_time_signature = TIME_SIGNATURE_STYLES.fetch(command.lexeme)
      end
    end

    private

    attr_reader :cursor, :tempo_reader

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
        stream&.change_meter(symbolized(meter, stream), command.line)
      end
    end

    def symbolized(meter, stream)
      symbol = SYMBOLS_BY_METER[meter.to_s]
      (symbol && !stream&.numeric_time_signature) ? HeadMusic::Rudiment::Meter.for_symbol(symbol) : meter
    end

    def read_tempo(command, stream)
      tempo = tempo_reader.read(command)
      stream&.change_tempo(tempo, command.line)
    end

    def read_clef(command, stream)
      token = cursor.advance
      raise cursor.error("\\clef expects a clef name", token || command) unless clef_name?(token)

      stream&.clef(token.lexeme)
    end

    # Its pitch is absolute even inside \relative, and leaves the relative
    # reference alone.
    def read_transposition(command, stream)
      token = cursor.advance
      unless token&.type == :note && token.duration.nil? && token.multiplier.nil?
        raise cursor.error("\\transposition expects a pitch", token || command)
      end

      step = HeadMusic::Notation::ConcertTransposition::Step.sounding(PitchReader.absolute.pitch(token))
      stream&.change_transposition(step, command.line)
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
