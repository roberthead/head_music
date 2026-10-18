module HeadMusic::Notation::MEI
  # Files a part's layers in one measure as PartReading::Layers, to wait
  # there until the part's voice keys are known: each on the staff it sits
  # on, each entry with the sounds of its notes and its ScoreReader::Pending
  # records, which are also added to the score's in document order. A layer
  # sits on its enclosing staff, unless every note and chord names the same
  # other staff of the part by @staff, as MuseScore writes a crossing hand.
  class PartLayers
    def initialize(state, editorial, ties, pending)
      @state = state
      @editorial = editorial
      @ties = ties
      @pending = pending
    end

    def read(reading, contents, index, where)
      staves = contents.to_h { |content| [content, sitting_staff(reading, content)] }.compare_by_identity
      pitches = PartSpelling.new(reading, @state, @editorial, @ties).pitches(contents, staves, where)
      contents.each do |content|
        entries = content.entries.map do |entry|
          sounds = entry.cue ? [] : entry.notes.map { |note| pitches.fetch(note) }
          [entry, sounds, note_pending(reading, entry, content, index, sounds, where.merge(staff: content.staff_number))]
        end
        reading.layers << PartReading::Layer.new(index, content, staves[content], entries)
      end
    end

    private

    def sitting_staff(reading, content)
      crossing = content.crossing_staff
      reading.definition.staff_index(crossing) ? crossing : content.staff_number
    end

    def note_pending(reading, entry, content, index, sounds, where)
      base = {measure_index: index, reading: reading, staff: entry.staff, content: content}
      records = [own_pending(entry, sounds, base, where)]
      records.concat(chord_tones(entry, sounds, base, where)) if entry.kind == :chord
      @pending.concat(records)
      records
    end

    def chord_tones(entry, sounds, base, where)
      entry.notes.zip(sounds).map do |note, sound|
        ScoreReader::Pending.new(kind: :note, element: note, chord_member: true, sound: sound, tie: TieControls.marker(note, entry, **where), **base)
      end
    end

    def own_pending(entry, sounds, base, where)
      kind = (entry.kind == :multi_rest) ? :m_rest : entry.kind
      note = kind == :note
      ScoreReader::Pending.new(
        kind: kind, element: entry.element, chord_member: false,
        sound: note ? sounds.first : nil, tie: note ? TieControls.marker(entry.element, entry, **where) : nil, **base
      )
    end
  end
end
