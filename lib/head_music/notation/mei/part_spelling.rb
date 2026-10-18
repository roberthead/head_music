module HeadMusic::Notation::MEI
  # The sounding pitch of every note of a part in one measure, by element,
  # each staff's notes taken in onset order across its layers, grace notes
  # before their note, so that an accidental holds for the notes after it.
  # A note is on the staff its @staff, or its chord's, names in the part,
  # else on the staff its layer sits on.
  class PartSpelling
    def initialize(reading, state, editorial, ties)
      @reading = reading
      @state = state
      @editorial = editorial
      @ties = ties
    end

    # +staves+ is the staff each content sits on.
    def pitches(contents, staves, where)
      by_staff = sorted_notes(contents).group_by { |note, entry, content| spelling_staff(note, entry, staves[content], where) }
      by_staff.each_with_object({}.compare_by_identity) do |(number, notes), pitches|
        accidentals = AccidentalReading.new(@state.written_fifths(number))
        notes.each do |note, entry, content|
          stream = [@reading.definition.index, staves[content], content.number, content.occurrence]
          pitches[note] = pitch(note, entry, stream, accidentals, where.merge(staff: number))
        end
      end
    end

    private

    def spelling_staff(note, entry, sitting, where)
      named = [note, entry.element].uniq.lazy.filter_map { |element| AttributeValues.read(element, "staff", **where, element: element) }.first
      @reading.definition.staff_index(named) ? named : sitting
    end

    def sorted_notes(contents)
      sequence = 0
      keyed = contents.flat_map do |content|
        content.entries.reject(&:cue).flat_map do |entry|
          entry.notes.map { |note| [[entry.cursor, entry.grace ? 0 : 1, sequence += 1], [note, entry, content]] }
        end
      end
      keyed.sort_by(&:first).map(&:last)
    end

    def pitch(note, entry, stream, accidentals, where)
      spelling = PitchReading.spelling(note, @editorial, **where)
      marker = TieControls.marker(note, entry, **where)
      alteration = accidentals.alteration(spelling, carried: @ties.carried(note, spelling, marker, stream))
      @ties.remember(note, spelling, marker, stream, alteration)
      written = HeadMusic::Notation::PitchSpelling.spelled(
        spelling.letter, alteration, spelling.octave, errors: HeadMusic::Notation::MEI, **where, element: note
      )
      @reading.transposition.concert(written, @reading.definition.staff_index(where[:staff]), **where, element: note)
    end
  end
end
