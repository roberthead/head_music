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
    MUSIC_TYPES = %i[open_brace note open_chord].freeze

    Grace = Data.define(:pitches, :rhythmic_value, :slashed, :tied, :marks) do
      # A tie holds only into a note of the same pitches.
      def before(follower)
        with(tied: tied && pitches.sort == follower.sort)
      end

      def grace_note
        HeadMusic::Content::GraceNote.new(
          sounds: pitches, rhythmic_value: rhythmic_value, slashed: slashed, tied: tied, articulations: marks.articulations
        )
      end
    end

    # The grace notes waiting for their main note.
    Graces = Data.define(:graces, :implied_slur) do
      def +(other)
        with(graces: graces + other.graces, implied_slur: implied_slur || other.implied_slur)
      end

      def before(pitches)
        graces.zip(graces.drop(1).map(&:pitches) + [pitches]).map { |grace, follower| grace.before(follower) }
      end

      # The main note takes its grace notes' levels and hairpins, and the
      # slurs they end. A slur opened on the first grace note starts there.
      def main_marks(marks)
        grace_marks = graces.map(&:marks)
        MarkReader::Marks.new(
          level: marks.level || grace_marks.filter_map(&:level).last,
          hairpin_marks: grace_marks.flat_map(&:hairpin_marks),
          span_marks: implied_slur_marks + grace_span_marks
        ).merge(marks.with(level: nil))
      end

      private

      def first_span_marks
        graces.first&.marks&.span_marks || []
      end

      def grace_span_marks
        first_span_marks.map(&:on_grace) + graces.drop(1).flat_map { |grace| grace.marks.span_marks }
      end

      def implied_slur_marks
        return [] unless implied_slur
        return [] if first_span_marks.any? { |mark| mark.opens?(:slur) }

        [
          MarkReader::SpanMark.new(kind: :slur, opening: true, id: IMPLIED_SLUR_ID, from_grace: true),
          MarkReader::SpanMark.new(kind: :slur, opening: false, id: IMPLIED_SLUR_ID)
        ]
      end
    end

    NONE = Graces.new(graces: [], implied_slur: false)

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
      else raise cursor.unexpected(token, %(Unexpected token "#{token.lexeme}" inside grace music))
      end
    end

    def read_grace
      pitches, rhythmic_value, _line, marks, tie = items.read_marked_sounds
      @graces << Grace.new(pitches: pitches, rhythmic_value: rhythmic_value, slashed: @slashed, tied: !tie.nil?, marks: marks)
    end

    def skip_silence
      items.carry_duration(cursor.advance)
      mark_reader.read
    end
  end
end
