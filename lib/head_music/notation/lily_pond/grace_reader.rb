# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads a grace command and the music after it: one note or chord, or a
  # braced run of them. Their pitches and durations go through the readers
  # the notes do, so a grace note sets the \relative reference and the
  # carried duration for what follows, even where it is then dropped.
  #
  # \appoggiatura and \acciaccatura imply a slur from the first grace note to
  # the main note, unless the first grace note opens one of its own.
  class GraceReader
    # Each command's [slashed, implied slur].
    COMMANDS_BY_NAME = {
      "grace" => [false, false], "slashedGrace" => [true, false],
      "appoggiatura" => [false, true], "acciaccatura" => [true, true]
    }.freeze
    COMMANDS = COMMANDS_BY_NAME.keys.freeze
    IMPLIED_SLUR_ID = :grace

    Grace = Data.define(:pitches, :rhythmic_value, :slashed, :tied, :marks)

    # The grace notes waiting for their main note.
    Graces = Data.define(:graces, :implied_slur) do
      def +(other)
        with(graces: graces + other.graces, implied_slur: implied_slur || other.implied_slur)
      end

      # Each tie holds only into a note of the same pitches.
      def before(pitches)
        followers = graces.drop(1).map(&:pitches) + [pitches]
        graces.zip(followers).map { |grace, follower| grace.with(tied: grace.tied && grace.pitches.sort == follower.sort) }
      end

      # The main note takes its grace notes' levels and hairpins, and the
      # slurs they end. A slur opened on the first grace note starts there.
      def main_marks(marks)
        MarkReader::Marks.new(
          level: marks.level || graces.filter_map { |grace| grace.marks.level }.last,
          hairpin_marks: graces.flat_map { |grace| grace.marks.hairpin_marks },
          span_marks: implied_slur_marks + grace_span_marks
        ).merge(marks.with(level: nil))
      end

      private

      def grace_span_marks
        first, *others = graces
        first.marks.span_marks.map { |mark| mark.opening ? mark.with(from_grace: true) : mark } +
          others.flat_map { |grace| grace.marks.span_marks }
      end

      def implied_slur_marks
        return [] unless implied_slur
        return [] if graces.first.marks.span_marks.any? { |mark| mark.opening && mark.kind == :slur }

        [
          MarkReader::SpanMark.new(kind: :slur, opening: true, id: IMPLIED_SLUR_ID, from_grace: true),
          MarkReader::SpanMark.new(kind: :slur, opening: false, id: IMPLIED_SLUR_ID)
        ]
      end
    end

    def initialize(cursor, items)
      @cursor = cursor
      @items = items
      @mark_reader = MarkReader.new(cursor)
    end

    # The grace notes the command at the cursor writes, or the music after a
    # command already read.
    def read(command = cursor.advance)
      @slashed, implied_slur = COMMANDS_BY_NAME.fetch(command.lexeme, [false, false])
      @graces = []
      read_music(command)
      Graces.new(graces: @graces, implied_slur: implied_slur)
    end

    private

    attr_reader :cursor, :items, :mark_reader

    def read_music(command)
      case cursor.peek&.type
      when :open_brace then read_braces
      when :note, :open_chord then read_grace
      else raise cursor.error("\\#{command.lexeme} expects music", cursor.peek || command)
      end
    end

    def read_braces
      cursor.advance
      read_item until cursor.peek.type == :close_brace
      cursor.advance
    end

    def read_item
      token = cursor.peek
      case token.type
      when :note, :open_chord then read_grace
      when :rest, :spacer then skip_silence
      when :open_brace then read_braces
      when :bar_check then cursor.advance
      when :tuplet then raise cursor.unsupported("Tuplets inside grace music are not supported", token)
      when :command then raise cursor.unsupported_command(token)
      when :unsupported then raise cursor.unsupported_token(token)
      else raise cursor.error(%(Unexpected token "#{token.lexeme}" inside grace music), token)
      end
    end

    def read_grace
      token = cursor.peek
      raise cursor.unsupported("A <> inside grace music is not supported", token) if token.type == :open_chord && items.marker?

      pitches, rhythmic_value, = items.read_sounds
      marks = mark_reader.read
      tied = cursor.peek&.type == :tie
      cursor.advance if tied
      marks = mark_reader.read(marks) if tied
      @graces << Grace.new(pitches: pitches, rhythmic_value: rhythmic_value, slashed: @slashed, tied: tied, marks: marks)
    end

    def skip_silence
      items.carry_duration(cursor.advance)
      mark_reader.read
    end
  end
end
