module HeadMusic::Notation::MEI
  # The sounding alteration of every note on one staff in one bar, inverting
  # AccidentalPlan. Notes are taken in onset order across the staff's
  # layers, grace notes before their note. A note sounds its @accid.ges, or
  # else its @accid, and a shown accidental holds for later notes at that
  # letter and octave in the bar; a note with neither sounds what a tie
  # carries into it, or else what the key or such an earlier accidental
  # implies.
  class AccidentalReading
    def initialize(fifths)
      @key = AccidentalPlan.key_alterations(fifths)
      @memory = {}
    end

    def alteration(spelling, carried: nil)
      place = [spelling.letter, spelling.octave]
      implied = @memory.fetch(place) { @key.fetch(spelling.letter, 0) }
      @memory[place] = spelling.written if spelling.written
      spelling.sounding || spelling.written || carried || implied
    end
  end
end
