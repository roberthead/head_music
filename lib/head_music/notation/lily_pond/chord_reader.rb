# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads the sounds of a < > chord: the pitches of the notes inside, read
  # together so \relative measures each from the one before, and the value
  # written on the closer. The notes inside carry no durations of their own.
  class ChordReader
    def initialize(cursor, items, readers)
      @cursor = cursor
      @items = items
      @readers = readers
    end

    def read
      opener = cursor.advance
      notes = []
      notes << note until cursor.peek.type == :close_chord
      [readers.current.chord_pitches(notes), items.rhythmic_value(cursor.advance), opener.line]
    end

    private

    attr_reader :cursor, :items, :readers

    def note
      token = cursor.advance
      raise cursor.unsupported_token(token) if token.type == :unsupported
      raise cursor.error(%(Unexpected token "#{token.lexeme}" inside a chord), token) unless token.type == :note
      raise cursor.error("Chord notes cannot carry durations", token) if token.duration

      items.reject_multiplier(token)
      token
    end
  end
end
