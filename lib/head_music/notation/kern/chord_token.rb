# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Joins the space-separated notes of one data field into one token. A
  # chord's notes must be as long, and tied alike, and it gathers the
  # markings of all of them. A field of grace notes alone is one grace
  # note, a chord when it has several, tied only where all its notes are.
  class ChordToken
    def self.of_notes(subtokens, field:, line_number: nil)
      new(subtokens, field, line_number).of_notes
    end

    def self.of_graces(graces, field:, line_number: nil)
      new(graces, field, line_number).of_graces
    end

    def initialize(tokens, field, line_number)
      @tokens = tokens
      @field = field
      @line_number = line_number
    end

    def of_notes
      return @tokens.first if @tokens.one?

      raise unsupported("A chord cannot hold a rest") if @tokens.any? { |token| token.type == :rest }
      raise unsupported("Chord notes with different durations are not supported") unless alike?(:fraction)
      raise unsupported("A chord tied only in part is not supported") unless alike?(:tie)

      joined(ornaments: union(:ornaments), note_dynamic: @tokens.filter_map(&:note_dynamic).first)
    end

    def of_graces
      joined(tie: alike?(:tie) ? @tokens.first.tie : nil)
    end

    private

    def joined(**fields)
      @tokens.first.with(
        pitches: @tokens.flat_map(&:pitches), articulations: union(:articulations), span_marks: span_marks, **fields
      )
    end

    def alike?(field)
      @tokens.map(&field).uniq.length == 1
    end

    def union(field)
      @tokens.flat_map(&field).uniq.sort
    end

    # A chord's notes may each repeat its slur, so a mark counts as often as
    # any one note has it.
    def span_marks
      tallies = @tokens.map { |token| token.span_marks.tally }
      tallies.flat_map(&:keys).uniq.flat_map { |mark| [mark] * tallies.map { |tally| tally.fetch(mark, 0) }.max }
    end

    def unsupported(message)
      UnsupportedFeatureError.new(%(#{message}: "#{@field}"), line_number: @line_number, snippet: @field)
    end
  end
end
