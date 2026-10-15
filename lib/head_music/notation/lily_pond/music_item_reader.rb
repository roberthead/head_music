# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads the items a sequence of music is made of — notes, rests, chords and
  # the marks after them, ties, bar checks, and \change Staff commands — into
  # the stream of the context that holds them. A SettingReader reads the \key,
  # \time, and \clef commands among them, and a GraceReader the grace notes
  # before a note. Everything that opens a level of its own belongs to the
  # MusicReader that calls this one.
  class MusicItemReader
    def initialize(cursor, readers)
      @cursor = cursor
      @readers = readers
      @duration_reader = DurationReader.new
      @mark_reader = MarkReader.new(cursor)
      @grace_reader = GraceReader.new(cursor, self)
    end

    def read_note(context)
      add_note(context, *read_sounds)
    end

    # The pitches, value, and line of the note or chord at the cursor, read
    # through the pitch and duration readers so they carry on to what follows.
    def read_sounds
      return read_chord_sounds if cursor.peek.type == :open_chord

      token = cursor.advance
      reject_multiplier(token)
      [[readers.current.pitch(token)], duration_reader.rhythmic_value(token), token.line]
    end

    # A rest or spacer's duration carries on, even where it is dropped.
    def carry_duration(token)
      duration_reader.rhythmic_value(token)
    end

    # Grace notes wait in the stream for the note they come before.
    def read_grace(context)
      context.stream.add_graces(grace_reader.read)
    end

    # \afterGrace's grace notes come after a note, which the model cannot
    # hold, so they are read and dropped.
    def skip_grace(command)
      grace_reader.read(command)
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
      return read_marker(context) if marker?

      add_note(context, *read_chord_sounds)
    end

    def marker?
      cursor.peek(1)&.type == :close_chord
    end

    # <> is a chord of no notes, so it takes no time and carries its marks to
    # where the music has reached: c'1\< <>\! ends a crescendo where the c'1
    # ends. A duration on it is carried forward, as on any chord.
    def read_marker(context)
      cursor.advance
      closer = cursor.advance
      reject_multiplier(closer)
      duration_reader.rhythmic_value(closer)
      context.stream.add_marker(closer.line, mark_reader.read)
    end

    # The mark \after places into the music that follows, which the caller
    # reads.
    def read_after(context)
      token = cursor.advance
      offset = duration_reader.offset_fraction(token)
      context.stream.add_after(offset, token.line, mark_reader.read_one("\\after"))
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

    attr_reader :cursor, :readers, :duration_reader, :mark_reader, :grace_reader

    def read_chord_sounds
      opener = cursor.advance
      notes = []
      notes << chord_note until cursor.peek.type == :close_chord
      closer = cursor.advance
      reject_multiplier(closer)
      [readers.current.chord_pitches(notes), duration_reader.rhythmic_value(closer), opener.line]
    end

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
