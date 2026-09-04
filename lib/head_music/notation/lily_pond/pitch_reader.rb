# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Converts note tokens into pitches in absolute or \relative mode.
  #
  # The two modes differ only in where octave marks count from: absolute
  # mode counts from c' as middle C, relative mode from the octave that
  # puts the letter within a fourth of the previous note. Accidentals never
  # influence the relative calculation; only letters do.
  class PitchReader
    LETTERS = %w[c d e f g a b].freeze
    # The letter step count beyond which relative mode wraps to the other octave.
    RELATIVE_REACH = 3
    # Register 3 is LilyPond's unmarked octave (c is C3), the inverse of PitchWriter.
    UNMARKED_REGISTER = 3
    FRAGMENTS_BY_SEMITONES = {0 => "", 1 => "#", -1 => "b", 2 => "x", -2 => "bb"}.freeze

    # The inverse of the writer's table, built lazily because the reader
    # loads before the writer.
    def self.alterations_by_suffix
      @alterations_by_suffix ||= PitchWriter::ALTERATION_SUFFIXES.invert.freeze
    end

    def self.absolute
      new(nil)
    end

    def self.relative(reference_pitch)
      new(HeadMusic::Rudiment::Pitch.get(reference_pitch))
    end

    def initialize(reference)
      @reference = reference
    end

    def relative?
      !@reference.nil?
    end

    def pitch(token)
      register = relative? ? relative_register(token) : absolute_register(token)
      resolved = build(token, register)
      @reference = resolved if relative?
      resolved
    end

    # Within a chord each note is relative to the one before it, and the
    # chord as a whole leaves its first note as the reference for what follows.
    def chord_pitches(tokens)
      pitches = tokens.map { |token| pitch(token) }
      @reference = pitches.first if relative?
      pitches
    end

    private

    def absolute_register(token)
      UNMARKED_REGISTER + mark_shift(token)
    end

    def relative_register(token)
      candidate = @reference.register * LETTERS.length + letter_index(token)
      difference = candidate - step(@reference)
      candidate -= LETTERS.length if difference > RELATIVE_REACH
      candidate += LETTERS.length if difference < -RELATIVE_REACH
      candidate += LETTERS.length * mark_shift(token)
      candidate.div(LETTERS.length)
    end

    def step(pitch)
      pitch.register * LETTERS.length + LETTERS.index(pitch.letter_name.to_s.downcase)
    end

    def letter_index(token)
      LETTERS.index(token.letter)
    end

    def mark_shift(token)
      marks = token.octave_marks.to_s
      marks.count("'") - marks.count(",")
    end

    def build(token, register)
      semitones = self.class.alterations_by_suffix.fetch(token.suffix.to_s)
      name = "#{token.letter.upcase}#{FRAGMENTS_BY_SEMITONES.fetch(semitones)}#{register}"
      HeadMusic::Rudiment::Pitch.from_name(name) ||
        raise(ParseError.new(
          %(Pitch "#{token.lexeme}" is out of range),
          line_number: token.line, column: token.column, snippet: token.lexeme
        ))
    end
  end
end
