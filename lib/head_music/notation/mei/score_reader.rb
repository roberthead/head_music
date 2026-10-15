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

    # What a bar of the score states: its meter and key, the tempo on its
    # downbeat, its control events, the children of the <measure> other
    # than its staves, and the passes of the <ending> it is in. A
    # <multiRest> of several bars makes a Measure of each, the controls in
    # the first.
    Measure = Struct.new(:index, :element, :number, :meter, :key, :tempo, :controls, :ending_passes)

    # A note of what one element became, in document order: for a <note>,
    # its track's event or grace note and the sound it added; for a chord
    # tone, chord_member. Kind is :note, :chord, :rest, :m_rest, :space, or
    # :m_space. One in a layer no voice reads, as MuseScore's whole-bar
    # rests beside another staff's layer of the same number, has no track.
    # +tie+ is a note's @tie, or its chord's, and +content+ the layer it is
    # read in.
    Pending = Struct.new(:kind, :element, :measure_index, :reading, :track, :event, :grace, :chord_member, :sound, :staff, :tie, :content)

    Score = Data.define(:measures, :readings, :pending, :ties)

    attr_reader :readings

    def initialize(source, groups, opening, identity)
      @source = source
      @editorial = source.editorial
      @groups = groups
      @readings = groups.parts.map { |definition| PartReading.new(definition) }
      transpose(@readings, groups.staff_numbers.filter_map { |number| opening_transposition(groups, number) }.to_h)
      @state = StaffState.new(opening, groups, @editorial, identity)
      @opening_score_def = opening.score_def
      @ties = TieControls.new(source.index)
      @tuplets = TupletSpans.new(source.index)
      @measures = []
      @pending = []
    end

    def read
      walk(@source.score, 1)
      mark_pickup
      @readings.each { |reading| VoiceAssignment.new(reading, @editorial).assign }
      groups = @tuplets.groups
      @readings.each { |reading| reading.tuplet_groups = groups }
      Score.new(@measures, @readings, @pending, @ties)
    end

    private

    def walk(container, depth, passes = nil)
      raise ParseError.new("<section>s nest deeper than #{Editorial::MAX_DEPTH}", element: container) if depth > Editorial::MAX_DEPTH

      endings = 0
      @editorial.children(container).each do |child|
        case child.name
        when "section" then walk(child, depth + 1, passes)
        when "ending" then walk(child, depth + 1, EndingPasses.passes(child, endings += 1, measure: next_number))
        when "measure" then read_measure(child, passes)
        when "scoreDef" then @state.apply_score_def(child, measure: next_number) unless child.equal?(@opening_score_def)
        when "staffDef" then @state.apply_staff_def(child, measure: next_number)
        end
      end
    end

    def next_number
      @measures.last&.number
    end

    def opening_transposition(groups, number)
      staff_def = groups.staff_def(number)
      step = staff_def && StaffState.transposition(staff_def, staff: number)
      [number, step] if step
    end

    # Each staff's transposition from the next note read on it.
    def transpose(readings, steps)
      steps.each do |number, step|
        reading = readings.find { |candidate| candidate.definition.staff_index(number) }
        reading&.transposition&.change(reading.definition.staff_index(number), step)
      end
    end

    # A first measure is a pickup where it says it is an upbeat, or where
    # every part's music in it is shorter than its meter.
    def mark_pickup
      first = @measures.first
      return unless first

      extent = @readings.filter_map { |reading| reading.measures.first.extent }.max
      upbeat = attribute(first.element, "type", element: first.element) == "upbeat"
      short = extent && extent < Rational(first.meter.top_number, first.meter.bottom_number)
      @readings.each { |reading| reading.measures.first.implicit = upbeat || short || false }
    end

    def read_measure(element, passes)
      where = {measure: attribute(element, "n", element: element)}
      staves, controls = staves_and_controls(element, where)
      @ties.note_controls(controls, where)
      @tuplets.note_controls(controls, where)
      changes = @state.take_changes
      transpose(@readings, changes.transpositions)
      contents = @readings.to_h { |reading| [reading, read_contents(reading, staves, where)] }
      OpenSpaces.resolve(contents.values.flatten, @state.meter, where)
      index = @measures.length
      bar_count(contents).times { |offset| add_measure(element, index + offset, offset.zero? ? controls : [], passes, where) }
      @readings.each do |reading|
        reading.measures[index].extent = extent(contents[reading], index)
        change_clefs(reading, index, changes, contents[reading]) if index.positive?
        reading.instrument_changes[index] = changes.instruments[reading.definition.index] if changes.instruments.key?(reading.definition.index)
        read_part(reading, contents[reading], index, where)
      end
    end

    # How far a part's music reaches in a measure. After the first, a
    # whole-bar rest fills its bar, so a layer beside it that ends short is
    # padded rather than making the bar short.
    def extent(contents, index)
      reach = contents.filter_map(&:extent).max
      return reach if index.zero? || contents.none? { |content| content.entries.any?(&:fills_bar?) }

      meter = @measures[index].meter
      [reach, Rational(meter.top_number, meter.bottom_number)].compact.max
    end

    # The bars a measure stands for: one, or as many as a <multiRest> fills.
    def bar_count(contents)
      contents.values.flatten.flat_map(&:entries).select { |entry| entry.kind == :multi_rest }.map(&:bars).max || 1
    end

    def add_measure(element, index, controls, passes, where)
      meter = @state.meter
      @measures << Measure.new(
        index: index, element: element, number: where[:measure], meter: meter, key: @state.key,
        tempo: tempo(controls, meter, where), controls: controls, ending_passes: passes
      )
      implicit = index.positive? && AttributeValues.read(element, "metcon", **where, element: element) == false
      @readings.each do |reading|
        reading.measures << PartReading::Measure.new(
          index: index, number: where[:measure], implicit: implicit, meter: meter, tolerance: PartReading::TOLERANCE, clefs: {}
        )
      end
    end

    # The tempo a <tempo> states on the downbeat by @mm, in its @mm.unit,
    # or else by @midi.bpm, in quarter notes. One in the middle of the bar,
    # or with text only, is skipped.
    def tempo(controls, meter, where)
      controls.each do |control|
        next unless control.name == "tempo" && downbeat?(control, meter, where)

        found = TempoReading.tempo(control, **where)
        return found if found
      end
      nil
    end

    def downbeat?(control, meter, where)
      tstamp = AttributeValues.read(control, "tstamp", **where, element: control, count: meter.top_number)
      tstamp ? tstamp == 1 : attribute(control, "startid", element: control).nil?
    end

    # A clef change between measures, or a clef that opens a layer.
    def change_clefs(reading, index, changes, contents)
      clefs = reading.measures[index].clefs
      contents.each do |content|
        clefs[reading.definition.staff_index(content.staff_number)] ||= content.opening_clef if content.opening_clef
      end
      changes.clefs.each do |number, clef|
        staff = reading.definition.staff_index(number)
        clefs[staff] = clef if staff
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

    def read_contents(reading, staves, where)
      reading.definition.staff_numbers.flat_map do |number|
        staves[number].flat_map { |staff| read_layers(staff, number, where.merge(staff: number)) }
      end
    end

    # Each layer's notes are spelled on the staff it sits on, and its
    # events wait in a PartReading::Layer, with their Pending records, until
    # the part's voice keys are known.
    def read_part(reading, contents, index, where)
      staves = contents.to_h { |content| [content, sitting_staff(reading, content)] }.compare_by_identity
      pitches = spell(reading, contents, staves, where)
      contents.each do |content|
        entries = content.entries.map do |entry|
          sounds = entry.cue ? [] : entry.notes.map { |note| pitches.fetch(note) }
          [entry, sounds, note_pending(reading, entry, content, index, sounds, where.merge(staff: content.staff_number))]
        end
        reading.layers << PartReading::Layer.new(index, content, staves[content], entries)
      end
    end

    # The enclosing staff, unless every note and chord names the same other
    # staff of the part by @staff, as MuseScore writes a crossing hand.
    def sitting_staff(reading, content)
      crossing = content.crossing_staff
      reading.definition.staff_index(crossing) ? crossing : content.staff_number
    end

    def read_layers(staff, number, where)
      @editorial.children_named(staff, "layer").map do |layer|
        LayerReader.new(layer, @editorial, staff_number: number, tuplets: @tuplets, duration_default: @state.duration_default(number), **where).read
      end
    end

    # The sounding pitch of every note of the part in the measure, by
    # element, each staff's notes taken in onset order across its layers.
    def spell(reading, contents, staves, where)
      contents.group_by { |content| staves[content] }.each_with_object({}.compare_by_identity) do |(number, staff_contents), pitches|
        accidentals = AccidentalReading.new(@state.written_fifths(number))
        sorted_notes(staff_contents).each do |note, entry, content|
          stream = [reading.definition.index, number, content.number]
          pitches[note] = pitch(reading, note, entry, stream, accidentals, where.merge(staff: number))
        end
      end
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

    def pitch(reading, note, entry, stream, accidentals, where)
      spelling = PitchReading.spelling(note, @editorial, **where)
      marker = TieControls.marker(note, entry, **where)
      alteration = accidentals.alteration(spelling, carried: @ties.carried(note, spelling, marker, stream))
      @ties.remember(note, spelling, marker, stream, alteration)
      written = HeadMusic::Notation::PitchSpelling.spelled(
        spelling.letter, alteration, spelling.octave, errors: HeadMusic::Notation::MEI, **where, element: note
      )
      reading.transposition.concert(written, reading.definition.staff_index(stream[1]), **where, element: note)
    end

    def note_pending(reading, entry, content, index, sounds, where)
      kind = (entry.kind == :multi_rest) ? :m_rest : entry.kind
      base = {measure_index: index, reading: reading, staff: entry.staff, content: content}
      tie = (kind == :note) ? TieControls.marker(entry.element, entry, **where) : nil
      pending = [Pending.new(kind: kind, element: entry.element, chord_member: false, sound: (kind == :note) ? sounds.first : nil, tie: tie, **base)]
      @pending.concat(pending)
      return pending unless entry.kind == :chord

      members = entry.notes.zip(sounds).map do |note, sound|
        Pending.new(kind: :note, element: note, chord_member: true, sound: sound, tie: TieControls.marker(note, entry, **where), **base)
      end
      @pending.concat(members)
      pending + members
    end
  end
end
