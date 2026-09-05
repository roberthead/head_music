# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads the items a sequence of music is made of — notes, rests, chords,
  # ties, bar checks, and the \key, \time, and \clef commands that appear
  # among them — into the stream of the context that holds them. Everything
  # that opens a level of its own belongs to the MusicReader that calls this
  # one.
  class MusicItemReader
    def initialize(cursor, readers)
      @cursor = cursor
      @readers = readers
      @duration_reader = DurationReader.new
    end

    def read_note(context)
      token = cursor.advance
      reject_multiplier(token)
      pitch = readers.current.pitch(token)
      context.stream.add_note([pitch], duration_reader.rhythmic_value(token), token.line)
    end

    def read_rest(context)
      token = cursor.advance
      reject_multiplier(token)
      context.stream.add_rest(duration_reader.rhythmic_value(token), token.line)
    end

    def read_whole_bar_rest(context)
      token = cursor.advance
      context.stream.add_whole_bar_rest(duration_reader.whole_bar_fraction(token), token.line)
    end

    def read_chord(context)
      opener = cursor.advance
      notes = []
      notes << chord_note until cursor.peek.type == :close_chord
      closer = cursor.advance
      raise cursor.error("Empty chord", opener) if notes.empty?

      reject_multiplier(closer)
      pitches = readers.current.chord_pitches(notes)
      context.stream.add_note(pitches, duration_reader.rhythmic_value(closer), opener.line)
    end

    def read_tie(context)
      context.stream.open_tie(cursor.advance.line)
    end

    def read_bar_check(context)
      context.stream.bar_check(cursor.advance.line)
    end

    def read_key(context)
      command = cursor.advance
      pitch_token = cursor.advance
      mode_token = cursor.advance
      located(command) do
        context.stream.change_key_signature(KeyReader.key_signature(pitch_token, mode_token), command.line)
      end
    end

    def read_time(context)
      command = cursor.advance
      meter_token = cursor.advance
      located(command) { context.stream.change_meter(MeterReader.meter(meter_token), command.line) }
    end

    def read_clef
      command = cursor.advance
      token = cursor.advance
      return if token && (%i[word string].include?(token.type) || (token.type == :note && token.duration.nil?))

      raise cursor.error("\\clef expects a clef name", token || command)
    end

    private

    attr_reader :cursor, :readers, :duration_reader

    def chord_note
      token = cursor.advance
      raise cursor.unsupported_token(token) if token.type == :unsupported
      raise cursor.error(%(Unexpected token "#{token.lexeme}" inside a chord), token) unless token.type == :note
      raise cursor.error("Chord notes cannot carry durations", token) if token.duration

      reject_multiplier(token)
      token
    end

    def reject_multiplier(token)
      return unless token.multiplier

      raise cursor.unsupported("Duration multipliers on notes and rests are not supported", token)
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
