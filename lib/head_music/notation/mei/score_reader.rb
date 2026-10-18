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

    Score = Data.define(:measures, :readings, :pending, :ties) do
      # Each element's Pending, by identity.
      def pending_by_element
        pending.each_with_object({}.compare_by_identity) { |pending, by_element| by_element[pending.element] = pending }
      end
    end

    attr_reader :readings

    def initialize(source, groups, opening, identity)
      @source = source
      @editorial = source.editorial
      @groups = groups
      @readings = groups.parts.map { |definition| PartReading.new(definition) }
      @state = StaffState.new(opening, groups, @editorial, identity)
      transpose(@state.steps)
      @opening_score_def = opening.score_def
      @ties = TieControls.new(source.index)
      @tuplets = TupletSpans.new(source.index)
      @measures = []
      @pending = []
      @layers = PartLayers.new(@state, @editorial, @ties, @pending)
      @clefs = MeasureClefs.new
      @definitions = []
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
        when "scoreDef" then @definitions << child unless child.equal?(@opening_score_def)
        when "staffDef" then @definitions << child unless @groups.opening?(child)
        end
      end
    end

    def next_number
      @measures.last&.number
    end

    # Each staff's transposition from the next note read on it.
    def transpose(steps)
      steps.each do |number, step|
        definition = @groups.part_for(number)
        @readings[definition.index].transposition.change(definition.staff_index(number), step)
      end
    end

    def mark_pickup
      first = @measures.first
      return unless first

      measures = @readings.map { |reading| reading.measures.first }
      pickup = MeasureLength.pickup?(first.element, first.meter, measures.map(&:extent))
      measures.each { |measure| measure.implicit = pickup }
    end

    def read_measure(element, passes)
      where = {measure: attribute(element, "n", element: element)}
      apply_definitions(where)
      contents = MeasureContents.new(element, where, groups: @groups, state: @state, editorial: @editorial, tuplets: @tuplets)
      @ties.note_controls(contents.controls, where)
      @tuplets.note_controls(contents.controls, where)
      changes = @state.take_changes
      transpose(changes.transpositions)
      contents.read(@readings)
      contents.all.each { |content| @state.change_key(content.staff_number, content.opening_key) if content.opening_key }
      index = @measures.length
      add_measures(element, contents, passes, where)
      @readings.each { |reading| file_part(reading, contents[reading], index, changes, where) }
    end

    def file_part(reading, contents, index, changes, where)
      measure = reading.measures[index]
      measure.extent = MeasureLength.extent(contents, measure)
      @clefs.open(reading, measure, changes, contents)
      instrument = changes.instruments[reading.definition.index]
      reading.instrument_changes[index] = instrument if instrument
      @layers.read(reading, contents, index, where)
      @clefs.close(reading, measure, contents)
    end

    # The <scoreDef>s and <staffDef>s since the last measure, which take
    # effect at this one and name it in their errors.
    def apply_definitions(where)
      @definitions.each do |definition|
        if definition.name == "scoreDef"
          @state.apply_score_def(definition, **where)
        else
          @state.apply_staff_def(definition, **where)
        end
      end
      @definitions.clear
    end

    # The bars a measure stands for: one, or as many as a <multiRest> fills,
    # within the bars the document's measures allow.
    def bar_count(contents, where)
      rest = contents.longest_multi_rest
      bars = rest&.bars || 1
      if @measures.length + bars > @source.bar_budget
        raise ParseError.new("<multiRest>s fill more than #{@source.bar_budget} bars", **where, element: rest&.element)
      end

      bars
    end

    # The later bars of a <multiRest> repeat its first without its tempo
    # and controls.
    def add_measures(element, contents, passes, where)
      bars = bar_count(contents, where)
      controls = contents.controls
      meter = @state.meter
      tempo = DownbeatTempo.tempo(controls, contents.entries, meter, @source.index, **where)
      index = @measures.length
      bars.times do |offset|
        measure = Measure.new(
          index: index + offset, element: element, number: where[:measure], meter: meter, key: @state.key,
          tempo: tempo, controls: controls, ending_passes: passes
        )
        add_measure(measure, where)
        tempo, controls = nil, []
      end
    end

    def add_measure(measure, where)
      @measures << measure
      index = measure.index
      implicit = MeasureLength.short?(measure.element, index, **where)
      @readings.each do |reading|
        reading.measures << PartReading::Measure.new(
          index: index, number: measure.number, implicit: implicit, meter: measure.meter, tolerance: PartReading::TOLERANCE, clefs: {}
        )
      end
    end
  end
end
