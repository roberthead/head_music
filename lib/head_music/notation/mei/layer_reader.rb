module HeadMusic::Notation::MEI
  # Reads one <layer> into entries in document order, each at the cursor it
  # starts at, an exact fraction of a whole note from the start of the
  # measure. Containers are walked through: <beam>, <tuplet>, <graceGrp>,
  # <bTrem>, whose note or chord reads alone, and <fTrem>, whose members
  # read in sequence at their own @dur. The tremolo itself is skipped.
  #
  # A <note> or <chord> takes its @dur, else its chord's, else for a chord
  # the @dur its notes all share, else the @dur.default in force; with
  # none, it raises. A <tuplet>, or a
  # <tupletSpan> through TupletSpans, scales the entries in it, and each is
  # a run to group. A grace note takes no time and no tuplet ratio, and one
  # with no @dur is an eighth. A @cue note is a rest, and a cue grace note
  # is dropped. <rest> and <space> are rests of their length, one of none
  # taking what OpenSpaces gives it, and <mRest>, <mSpace>, and
  # <multiRest> fill their bars. A <clef> before the first entry is the
  # layer's opening clef, and one after the last is its closing clef, as
  # MuseScore writes a change at the end of the bar before it. One in
  # between is skipped, as are <barLine> and every element the reader does
  # not use.
  # Measure repeats raise, since what they repeat is no music of their own.
  class LayerReader
    include XmlReading

    # +kind+ is :note, :chord, :rest, :space, :m_rest, :m_space, or
    # :multi_rest; +notes+ the <note>s it sounds; +bars+ how many bars a
    # <multiRest> fills.
    # +event+ and +track+ are where VoiceAssignment adds it.
    Entry = Struct.new(
      :kind, :element, :notes, :cursor, :rhythmic_value, :duration, :grace, :slashed, :cue, :staff, :bars, :event, :track
    ) do
      def fills_bar?
        %i[m_rest m_space multi_rest].include?(kind)
      end

      def sounding?
        !grace && !cue && %i[note chord].include?(kind)
      end

      # A <space> or <rest> whose length OpenSpaces decides.
      def open_space?
        %i[space rest].include?(kind) && rhythmic_value.nil?
      end
    end

    # A layer as read: its @n, its entries, how far its timed entries reach,
    # and the clefs it opens and closes with, if any.
    Content = Struct.new(:number, :element, :staff_number, :entries, :extent, :opening_clef, :closing_clef) do
      def notes?
        entries.any?(&:sounding?)
      end

      def placed?
        entries.any? { |entry| !entry.fills_bar? }
      end

      # The one @staff every note and chord names, or nil.
      def crossing_staff
        staves = entries.select(&:sounding?).map(&:staff).uniq
        staves.first if staves.length == 1
      end
    end

    # +run+ is the <tuplet> run its entries join.
    Context = Data.define(:grace, :slashed, :chord, :ratio, :run)
    PLAIN = Context.new(grace: false, slashed: false, chord: nil, ratio: nil, run: nil)

    REPEATS = %w[mRpt mRpt2 beatRpt halfmRpt multiRpt].freeze
    CONTAINERS = %w[beam tuplet bTrem fTrem].freeze
    MAX_DEPTH = 2 * Editorial::MAX_DEPTH

    def initialize(layer, editorial, staff_number:, tuplets:, duration_default: nil, **where)
      @layer = layer
      @editorial = editorial
      @staff_number = staff_number
      @tuplets = tuplets
      @duration_default = duration_default
      @where = where
      @number = AttributeValues.read(layer, "n", **where, element: layer) || 1
      @cursor = 0
      @extent = nil
      @entries = []
      @opening_clef = nil
      @last_clef = nil
    end

    def read
      walk(@layer, PLAIN, 1)
      Content.new(
        number: @number, element: @layer, staff_number: @staff_number, entries: @entries, extent: @extent,
        opening_clef: @opening_clef, closing_clef: closing_clef
      )
    end

    private

    def walk(element, context, depth)
      raise ParseError.new("A <layer> nests deeper than #{MAX_DEPTH}", **@where, element: element) if depth > MAX_DEPTH

      @editorial.children(element).each { |child| read_child(child, context, depth) }
    end

    def read_child(child, context, depth)
      case child.name
      when "note" then add_sounding(:note, child, [child], context)
      when "chord" then add_sounding(:chord, child, chord_notes(child), context.with(chord: child))
      when "rest", "space" then add_rest(child, context)
      when "mRest" then add_fill(:m_rest, child)
      when "mSpace" then add_fill(:m_space, child)
      when "multiRest" then add_fill(:multi_rest, child, bars: value(child, "num") || 1)
      when "graceGrp" then walk(child, grace_context(child, context), depth + 1)
      when *CONTAINERS then walk(child, container_context(child, context), depth + 1)
      when "clef" then read_clef(child)
      when *REPEATS then raise UnsupportedFeatureError.new("A <#{child.name}> is not supported", **@where, element: child)
      end
    end

    # The context a container's members read in: a <tuplet> scales them by
    # its ratio, and one inside another raises.
    def container_context(element, context)
      return context unless element.name == "tuplet"

      ratio = TupletSpans.ratio(element, **@where)
      return context unless ratio

      TupletSpans.nested(**@where, element: element) if context.ratio
      run = TupletSpans::Run.new(ratio, [])
      @tuplets.add_run(run)
      context.with(ratio: ratio, run: run)
    end

    def grace_context(element, context)
      context.with(grace: true, slashed: value(element, "grace") || false)
    end

    def add_sounding(kind, element, notes, context)
      grace = context.grace || !attribute(element, "grace", **@where, element: element).nil?
      cue = value(element, "cue") || false
      return if grace && cue

      return add_grace(kind, element, notes, context) if grace

      span = @tuplets.enter(stream, [element, *notes], @where.merge(element: element))
      rhythmic = rhythmic_value(element, context, grace: false, ratio: ratio(context, span, element))
      entry = Entry.new(kind: kind, element: element, notes: notes, cursor: @cursor, rhythmic_value: rhythmic, grace: false, cue: cue, staff: staff_of(element, notes))
      advance(entry, rhythmic, context, span)
    end

    def add_grace(kind, element, notes, context)
      slashed = value(element, "grace")
      @entries << Entry.new(
        kind: kind, element: element, notes: notes, cursor: @cursor, rhythmic_value: rhythmic_value(element, context, grace: true, ratio: nil),
        grace: true, slashed: slashed.nil? ? context.slashed : slashed, cue: false, staff: staff_of(element, notes)
      )
    end

    def add_rest(element, context)
      return add_open_space(element) if value(element, "dur").nil? && @duration_default.nil?

      span = @tuplets.enter(stream, [element], @where.merge(element: element))
      rhythmic = rhythmic_value(element, PLAIN, grace: false, ratio: ratio(context, span, element))
      advance(Entry.new(kind: element.name.to_sym, element: element, notes: [], cursor: @cursor, rhythmic_value: rhythmic, grace: false, cue: false), rhythmic, context, span)
    end

    def add_open_space(element)
      @entries << Entry.new(kind: element.name.to_sym, element: element, notes: [], cursor: @cursor, grace: false, cue: false)
    end

    def stream
      [@staff_number, @number]
    end

    # A container inside a span of its ratio is absorbed into it.
    def ratio(context, span, element)
      TupletSpans.nested(**@where, element: element) if span && context.ratio && span.ratio != context.ratio
      context.ratio || span&.ratio
    end

    def add_fill(kind, element, bars: 1)
      @entries << Entry.new(kind: kind, element: element, notes: [], cursor: @cursor, grace: false, cue: false, bars: bars)
    end

    def advance(entry, rhythmic, context, span)
      entry.duration = rhythmic.fraction
      @entries << entry
      @cursor += entry.duration
      @extent = @cursor
      context.run&.entries&.push(entry)
      span&.run&.entries&.push(entry)
      @tuplets.mark(stream, value(entry.element, "tuplet"), entry)
    end

    def chord_notes(chord)
      notes = @editorial.children_named(chord, "note")
      raise ParseError.new("A <chord> has no <note>", **@where, element: chord) if notes.empty?

      notes
    end

    def rhythmic_value(element, context, grace:, ratio:)
      shared = (element.name == "chord" && value(element, "dur").nil?) ? shared_duration(element) : nil
      unit = value(element, "dur") || (context.chord && value(context.chord, "dur")) || shared&.first || @duration_default
      unit ||= "eighth" if grace
      raise ParseError.new("A <#{element.name}> has no @dur, and no @dur.default is in force", **@where, element: element) unless unit

      dots = value(element, "dots") || (context.chord && value(context.chord, "dots")) || shared&.last || 0
      HeadMusic::Rudiment::RhythmicValue.new(unit, dots: dots, tuplet: ratio)
    end

    # The @dur and @dots every note of a chord states alike, or nil.
    def shared_duration(chord)
      durations = chord_notes(chord).map { |note| [value(note, "dur"), value(note, "dots")] }.uniq
      durations.first if durations.one? && durations.first.first
    end

    # A chord's @staff, else the one its notes share.
    def staff_of(element, notes)
      staff = value(element, "staff")
      return staff if staff

      staves = notes.map { |note| value(note, "staff") }.uniq
      staves.first if staves.length == 1
    end

    def read_clef(element)
      return @last_clef = [element, @entries.length] unless @entries.empty?

      @opening_clef ||= ClefReading.clef(element, **@where, element: element)
    end

    def closing_clef
      element, count = @last_clef
      ClefReading.clef(element, **@where, element: element) if element && count == @entries.length
    end

    def value(element, name)
      AttributeValues.read(element, name, **@where, element: element)
    end
  end
end
