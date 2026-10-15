module HeadMusic::Notation::MEI
  # Phase one: a single walk over a score's sections in document order,
  # reading each <measure>'s layers into its parts' voice tracks and noting
  # every event, as a Pending record, for the readers that run once the
  # voices are placed.
  #
  # In each measure a part's layers are read first, and then the
  # accidentals of every staff in the part across its layers, so that the
  # notes are spelled in onset order before any is added to its track.
  class ScoreReader
    include XmlReading

    # What a bar of the score states: its meter and key, and its control
    # events, the children of the <measure> other than its staves.
    Measure = Struct.new(:index, :element, :number, :meter, :key, :controls)

    # A note of what one element became, in document order: for a <note>,
    # its track's event or grace note and the sound it added; for a chord
    # tone, chord_member. Kind is :note, :chord, :rest, :m_rest, :space, or
    # :m_space.
    Pending = Struct.new(:kind, :element, :measure_index, :reading, :track, :event, :grace, :chord_member, :sound, :staff)

    Score = Data.define(:measures, :readings, :pending)

    attr_reader :readings

    def initialize(source, groups, opening)
      @source = source
      @editorial = source.editorial
      @groups = groups
      @opening = opening
      @readings = groups.parts.map { |definition| PartReading.new(definition) }
      @measures = []
      @pending = []
      @meter = opening.meter
      @key = opening.key
    end

    def read
      walk(@source.score, 1)
      Score.new(@measures, @readings, @pending)
    end

    private

    def walk(container, depth)
      raise ParseError.new("<section>s nest deeper than #{Editorial::MAX_DEPTH}", element: container) if depth > Editorial::MAX_DEPTH

      @editorial.children(container).each do |child|
        case child.name
        when "section", "ending" then walk(child, depth + 1)
        when "measure" then read_measure(child)
        end
      end
    end

    def read_measure(element)
      where = {measure: attribute(element, "n", element: element)}
      staves, controls = staves_and_controls(element, where)
      index = @measures.length
      @measures << Measure.new(index: index, element: element, number: where[:measure], meter: @meter, key: @key, controls: controls)
      @readings.each do |reading|
        reading.measures << PartReading::Measure.new(
          index: index, number: where[:measure], implicit: false, meter: @meter, tolerance: PartReading::TOLERANCE, clefs: {}
        )
        read_part(reading, staves, index, where)
      end
    end

    def staves_and_controls(element, where)
      staves = Hash.new { |hash, number| hash[number] = [] }
      controls = []
      @editorial.children(element).each do |child|
        next controls << child unless child.name == "staff"

        number = AttributeValues.read(child, "n", **where, element: child) || 1
        raise ParseError.new("A <staff> numbered #{number} has no <staffDef>", **where, element: child) unless @groups.part_for(number)

        staves[number] << child
      end
      [staves, controls]
    end

    def read_part(reading, staves, index, where)
      contents = reading.definition.staff_numbers.flat_map do |number|
        staves[number].flat_map { |staff| read_layers(staff, number, where.merge(staff: number)) }
      end
      reading.measures[index].extent = contents.filter_map(&:extent).max
      pitches = spell(reading, contents, where)
      contents.each { |content| add_events(reading, content, index, pitches, where.merge(staff: content.staff_number)) }
    end

    def read_layers(staff, number, where)
      @editorial.children_named(staff, "layer").map do |layer|
        LayerReader.new(layer, @editorial, staff_number: number, duration_default: @opening.duration_default(number), **where).read
      end
    end

    # The sounding pitch of every note of the part in the measure, by
    # element, each staff's notes taken in onset order across its layers.
    def spell(reading, contents, where)
      contents.group_by(&:staff_number).each_with_object({}.compare_by_identity) do |(number, staff_contents), pitches|
        accidentals = AccidentalReading.new(@key.fifths)
        sorted_notes(staff_contents).each do |note|
          pitches[note] = pitch(reading, note, number, accidentals, where.merge(staff: number))
        end
      end
    end

    def sorted_notes(contents)
      sequence = 0
      keyed = contents.flat_map do |content|
        content.entries.reject(&:cue).flat_map do |entry|
          entry.notes.map { |note| [[entry.cursor, entry.grace ? 0 : 1, sequence += 1], note] }
        end
      end
      keyed.sort_by(&:first).map(&:last)
    end

    def pitch(reading, note, number, accidentals, where)
      spelling = PitchReading.spelling(note, @editorial, **where)
      written = HeadMusic::Notation::PitchSpelling.spelled(
        spelling.letter, accidentals.alteration(spelling), spelling.octave, errors: HeadMusic::Notation::MEI, **where, element: note
      )
      reading.transposition.concert(written, reading.definition.staff_index(number), **where, element: note)
    end

    def add_events(reading, content, index, pitches, where)
      track = reading.track(content.number)
      staff = reading.definition.staff_index(content.staff_number)
      content.entries.each do |entry|
        note_sounds = entry.cue ? [] : entry.notes.map { |note| pitches.fetch(note) }
        if entry.grace
          add_grace(reading, track, entry, note_sounds, index)
        else
          add_event(reading, track, entry, note_sounds, index, staff)
        end
      end
    end

    def add_grace(reading, track, entry, note_sounds, index)
      grace = track.queue_grace(
        sounds: note_sounds.uniq, rhythmic_value: entry.rhythmic_value, slashed: entry.slashed, articulations: [], tie_starts: []
      )
      note_pending(reading, track, entry, index, note_sounds, grace: grace)
    end

    def add_event(reading, track, entry, note_sounds, index, staff)
      event = track.add(
        measure_index: index, cursor: entry.cursor, tolerance: PartReading::TOLERANCE,
        rhythmic_value: entry.fills_bar? ? nil : entry.rhythmic_value, duration: entry.duration || 0, sounds: note_sounds.uniq,
        fills_bar: entry.fills_bar?, cue: entry.cue, tie_starts: [], tie_stops: [], staff: staff
      )
      note_pending(reading, track, entry, index, note_sounds, event: event)
    end

    def note_pending(reading, track, entry, index, note_sounds, event: nil, grace: nil)
      kind = (entry.kind == :multi_rest) ? :m_rest : entry.kind
      base = {measure_index: index, reading: reading, track: track, event: event, grace: grace, staff: entry.staff}
      @pending << Pending.new(kind: kind, element: entry.element, chord_member: false, sound: (kind == :note) ? note_sounds.first : nil, **base)
      return unless entry.kind == :chord

      entry.notes.zip(note_sounds).each do |note, sound|
        @pending << Pending.new(kind: :note, element: note, chord_member: true, sound: sound, **base)
      end
    end
  end
end
