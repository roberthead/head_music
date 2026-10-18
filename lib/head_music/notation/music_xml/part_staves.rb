# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # A part's staves as its <attributes> state them: how many there are, the
  # most there ever are, the symbol joining them, and what each transposes,
  # by which a note on one sounds.
  class PartStaves
    attr_reader :most, :part_symbol

    def initialize(instrument: nil)
      @instrument = instrument
      @count = 1
      @most = 1
      @part_symbol = nil
      @transposition = HeadMusic::Notation::ConcertTransposition.new(errors: HeadMusic::Notation::MusicXML)
    end

    def change(attributes)
      @count = attributes.staves if attributes.staves
      @most = [@most, @count].max
      @part_symbol ||= attributes.part_symbol
      attributes.transpositions.each { |number, step| @transposition.change(number, step) }
    end

    def staff(note, **where)
      number = note.staff || 1
      raise ParseError.new("A <staff> of #{number} is not positive", **where) unless number.positive?
      raise ParseError.new("A <staff> of #{number} is beyond the part's #{@count} staves", **where) if number > @count

      number
    end

    # A transposing part's key lands in concert pitch, as its notes do.
    def concert_key(key)
      fifths, mode = key
      [@transposition.concert_fifths(fifths), mode]
    end

    # A pitch sounds where its staff's transposition puts it. An unpitched
    # note is a sound of the part's instrument, or an unpitched sound of
    # none.
    def sound(note, **where)
      return @transposition.concert(note.pitch, note.staff || 1, **where) unless note.unpitched

      HeadMusic::Rudiment::UnpitchedSound.get(@instrument) || HeadMusic::Rudiment::UnpitchedSound.get(nil)
    end
  end
end
