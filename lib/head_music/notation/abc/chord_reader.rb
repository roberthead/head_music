# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Resolves a bracket-chord token into the pitches it sounds and the one
  # length its notes share.
  class ChordReader
    def initialize(duration_resolver)
      @duration_resolver = duration_resolver
    end

    # Returns the chord's pitches and its shared inner length. Chord pitches
    # resolve in bracket order, so an explicit accidental inside a chord
    # persists for the rest of the bar like any other.
    def read(token, pitch_builder)
      pitches = token.notes.map do |note|
        pitch_builder.pitch(note.letter, note.octave_marks, note.accidental)
      end
      ensure_unique_pitches(pitches, token)
      [pitches, uniform_length(token)]
    end

    private

    attr_reader :duration_resolver

    def ensure_unique_pitches(pitches, token)
      return if pitches.uniq.length == pitches.length

      raise ParseError.new(
        "Chord pitches must be unique",
        line_number: token.line, snippet: snippet(token)
      )
    end

    # ABC 2.1 sec. 4.17 allows per-note lengths only when they agree; the
    # shared inner length then multiplies with any outer length. Unequal
    # lengths (whose ABC meaning is "the duration of the first note") would
    # need silent reinterpretation to fit one rhythmic value, so we reject.
    def uniform_length(token)
      fractions = token.notes.map { |note| duration_resolver.length_fraction(note.length) }
      return fractions.first if fractions.uniq.length == 1

      raise ParseError.new(
        'Chord notes must share one length; write it after the bracket ("[CEG]2") ' \
        'or repeat it on every note ("[C2E2G2]")',
        line_number: token.line, snippet: snippet(token)
      )
    end

    def snippet(token)
      inner = token.notes.map do |note|
        "#{note.accidental}#{note.letter}#{note.octave_marks}#{note.length}"
      end.join
      "[#{inner}]"
    end
  end
end
