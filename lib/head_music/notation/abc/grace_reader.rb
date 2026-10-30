# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Reads a group of grace notes into the grace notes the next note carries.
  # Lengths are relative to the unit note length, as a note's are. A grace
  # note keeps its articulations; a level or hairpin mark on it reads at its
  # main note, and its other decorations are dropped. One written as a tied
  # chain, which a grace note cannot hold, is skipped.
  class GraceReader
    def initialize(duration_resolver)
      @duration_resolver = duration_resolver
      @chord_reader = ChordReader.new(duration_resolver)
    end

    # The grace notes, and the decorations that wait for the main note.
    def read(token, pitch_builder)
      slashed = token.style == :slashed
      positional = []
      graces = token.notes.filter_map do |item|
        decorations = item.decorations.map { |lexeme| Decoration.from_token(Token.new(type: :decoration, line: token.line, column: token.column, lexeme: lexeme)) }
        positional.concat(decorations.select(&:positional?))
        grace_note(item, pitch_builder, slashed, decorations.select { |decoration| decoration.kind == :articulation }.map(&:key))
      end
      [graces, positional]
    end

    private

    def grace_note(item, pitch_builder, slashed, articulations)
      pitches, inner_length = @chord_reader.read(item, pitch_builder)
      rhythmic_value = @duration_resolver.rhythmic_duration(item.length, scale: inner_length).single_value
      return unless rhythmic_value

      HeadMusic::Content::GraceNote.new(
        sounds: pitches, rhythmic_value: rhythmic_value, slashed: slashed, tied: item.tied, articulations: articulations
      )
    end
  end
end
