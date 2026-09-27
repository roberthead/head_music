# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads the items a sequence of music is made of — notes, rests, chords and
  # the marks after them, ties, bar checks, and \change Staff commands — into
  # the stream of the context that holds them. A SettingReader reads the \key,
  # \time, and \clef commands among them. Everything that opens a level of its
  # own belongs to the MusicReader that calls this one.
  class MusicItemReader
    def initialize(cursor, readers)
      @cursor = cursor
      @readers = readers
      @duration_reader = DurationReader.new
      @mark_reader = MarkReader.new(cursor)
    end

    def read_note(context)
      token = cursor.advance
      reject_multiplier(token)
      pitch = readers.current.pitch(token)
      add_note(context, [pitch], duration_reader.rhythmic_value(token), token.line)
    end

    def read_rest(context)
      token = cursor.advance
      reject_multiplier(token)
      context.stream.add_rest(duration_reader.rhythmic_value(token), token.line, mark_reader.read)
    end

    def read_whole_bar_rest(context)
      token = cursor.advance
      context.stream.add_whole_bar_rest(duration_reader.whole_bar_fraction(token), token.line, mark_reader.read)
    end

    def read_spacer(context)
      token = cursor.advance
      context.stream.add_spacer(duration_reader.spacer_fraction(token), token.line, mark_reader.read)
    end

    def read_chord(context)
      opener = cursor.advance
      notes = []
      notes << chord_note until cursor.peek.type == :close_chord
      closer = cursor.advance
      raise cursor.error("Empty chord", opener) if notes.empty?

      reject_multiplier(closer)
      pitches = readers.current.chord_pitches(notes)
      add_note(context, pitches, duration_reader.rhythmic_value(closer), opener.line)
    end

    def read_tie(context)
      context.stream.open_tie(cursor.advance.line)
    end

    def read_bar_check(context)
      context.stream.bar_check(cursor.advance.line)
    end

    def read_staff_change(context)
      command = cursor.advance
      target = cursor.peek
      unless target&.type == :word && target.lexeme == "Staff"
        raise cursor.unsupported("\\change is supported only for a Staff", target || command)
      end

      cursor.advance
      cursor.expect(:equals, "\\change Staff expects = and a staff name")
      name = cursor.expect(:string, "\\change Staff expects a quoted staff name")
      context.stream.change_staff(name.lexeme, command.line)
    end

    private

    attr_reader :cursor, :readers, :duration_reader, :mark_reader

    # A tie is a mark like the others, so marks may follow it as well as
    # precede it: c4-.~\p is one note's staccato, tie, and dynamic.
    def add_note(context, pitches, rhythmic_value, line)
      marks = mark_reader.read
      tie = (cursor.peek&.type == :tie) ? cursor.advance : nil
      marks = mark_reader.read(marks) if tie
      context.stream.add_note(pitches, rhythmic_value, line, marks)
      context.stream.open_tie(tie.line) if tie
    end

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
  end
end
