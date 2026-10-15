module HeadMusic::Notation::MEI
  # What a <note> says of its pitch: its letter and octave, @pname.ges and
  # @oct.ges winning, and the accidental it sounds and the one it shows, by
  # attribute or by a child <accid>, each nil where it says nothing.
  module PitchReading
    Spelling = Data.define(:letter, :octave, :sounding, :written)

    module_function

    def spelling(note, editorial, **where)
      letter = value(note, "pname.ges", where) || value(note, "pname", where)
      raise ParseError.new("A <note> has no @pname", **where, element: note) unless letter

      octave = value(note, "oct.ges", where) || value(note, "oct", where)
      raise ParseError.new("A <note> has no @oct", **where, element: note) unless octave

      accids = editorial.children_named(note, "accid")
      Spelling.new(letter, octave, accidental(note, accids, "accid.ges", where), accidental(note, accids, "accid", where))
    end

    def accidental(note, accids, name, where)
      [note, *accids].each do |element|
        semitones = value(element, name, where)
        return semitones if semitones
      end
      nil
    end

    def value(element, name, where)
      AttributeValues.read(element, name, **where, element: element)
    end
  end
end
