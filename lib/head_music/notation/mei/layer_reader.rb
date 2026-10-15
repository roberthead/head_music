module HeadMusic::Notation::MEI
  # Reads one <layer> into entries in document order, each at the cursor it
  # starts at, an exact fraction of a whole note from the start of the
  # measure. Containers are walked through: <beam>, <tuplet>, <graceGrp>,
  # <bTrem>, whose note or chord reads alone, and <fTrem>, whose members
  # read in sequence at their own @dur. The tremolo itself is skipped.
  #
  # A <note> or <chord> takes its @dur, else its chord's, else the
  # @dur.default in force; with none, it raises. A grace note takes no time,
  # and one with no @dur is an eighth. A @cue note is a rest, and a cue
  # grace note is dropped. <rest> and <space> are rests of their length, and
  # <mRest>, <mSpace>, and <multiRest> fill their bars. A <clef> before the
  # first entry is the layer's opening clef; one later in the layer is
  # skipped, as are <barLine> and every element the reader does not use.
  # Measure repeats raise, since what they repeat is no music of their own.
  class LayerReader
    include XmlReading

    # +kind+ is :note, :chord, :rest, :space, :m_rest, :m_space, or
    # :multi_rest; +notes+ the <note>s it sounds; +bars+ how many bars a
    # <multiRest> fills.
    Entry = Struct.new(
      :kind, :element, :notes, :cursor, :rhythmic_value, :duration, :grace, :slashed, :cue, :staff, :bars
    ) do
      def fills_bar?
        %i[m_rest m_space multi_rest].include?(kind)
      end

      def sounding?
        !grace && !cue && %i[note chord].include?(kind)
      end
    end

    # A layer as read: its @n, its entries, how far its timed entries reach,
    # and the clef it opens with, if any.
    Content = Struct.new(:number, :element, :staff_number, :entries, :extent, :opening_clef) do
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

    Context = Data.define(:grace, :slashed, :chord, :ratio)

    REPEATS = %w[mRpt mRpt2 beatRpt halfmRpt multiRpt].freeze
    CONTAINERS = %w[beam tuplet bTrem fTrem].freeze
    MAX_DEPTH = 2 * Editorial::MAX_DEPTH

    def initialize(layer, editorial, staff_number:, duration_default: nil, **where)
      @layer = layer
      @editorial = editorial
      @staff_number = staff_number
      @duration_default = duration_default
      @where = where
      @cursor = 0
      @extent = nil
      @entries = []
      @opening_clef = nil
    end

    def read
      walk(@layer, Context.new(grace: false, slashed: false, chord: nil, ratio: nil), 1)
      Content.new(
        number: AttributeValues.read(@layer, "n", **@where, element: @layer) || 1, element: @layer,
        staff_number: @staff_number, entries: @entries, extent: @extent, opening_clef: @opening_clef
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
      when "rest", "space" then add_rest(child)
      when "mRest" then add_fill(:m_rest, child)
      when "mSpace" then add_fill(:m_space, child)
      when "multiRest" then add_fill(:multi_rest, child, bars: value(child, "num") || 1)
      when "graceGrp" then walk(child, grace_context(child, context), depth + 1)
      when *CONTAINERS then walk(child, container_context(child, context), depth + 1)
      when "clef" then read_clef(child)
      when *REPEATS then raise UnsupportedFeatureError.new("A <#{child.name}> is not supported", **@where, element: child)
      end
    end

    # The context a container's members read in. A <tuplet>'s ratio is
    # where tuplet reading plugs in; until then its members keep their
    # written values.
    def container_context(_element, context)
      context
    end

    def grace_context(element, context)
      context.with(grace: true, slashed: value(element, "grace") || false)
    end

    def add_sounding(kind, element, notes, context)
      grace = context.grace || !attribute(element, "grace", **@where, element: element).nil?
      cue = value(element, "cue") || false
      return if grace && cue

      rhythmic = rhythmic_value(element, context, grace: grace)
      slashed = value(element, "grace")
      entry = Entry.new(
        kind: kind, element: element, notes: notes, cursor: @cursor, rhythmic_value: rhythmic, grace: grace,
        slashed: grace && (slashed.nil? ? context.slashed : slashed), cue: cue, staff: staff_of(element, notes)
      )
      grace ? @entries << entry : advance(entry, rhythmic)
    end

    def add_rest(element)
      rhythmic = rhythmic_value(element, Context.new(grace: false, slashed: false, chord: nil, ratio: nil), grace: false)
      advance(Entry.new(kind: element.name.to_sym, element: element, notes: [], cursor: @cursor, rhythmic_value: rhythmic, grace: false, cue: false), rhythmic)
    end

    def add_fill(kind, element, bars: 1)
      @entries << Entry.new(kind: kind, element: element, notes: [], cursor: @cursor, grace: false, cue: false, bars: bars)
    end

    def advance(entry, value)
      entry.duration = value.fraction
      @entries << entry
      @cursor += entry.duration
      @extent = @cursor
    end

    def chord_notes(chord)
      notes = @editorial.children_named(chord, "note")
      raise ParseError.new("A <chord> has no <note>", **@where, element: chord) if notes.empty?

      notes
    end

    def rhythmic_value(element, context, grace:)
      unit = value(element, "dur") || (context.chord && value(context.chord, "dur")) || @duration_default
      unit ||= "eighth" if grace
      raise ParseError.new("A <#{element.name}> has no @dur, and no @dur.default is in force", **@where, element: element) unless unit

      dots = value(element, "dots") || (context.chord && value(context.chord, "dots")) || 0
      HeadMusic::Rudiment::RhythmicValue.new(unit, dots: dots, tuplet: context.ratio)
    end

    # A chord's @staff, else the one its notes share.
    def staff_of(element, notes)
      staff = value(element, "staff")
      return staff if staff

      staves = notes.map { |note| value(note, "staff") }.uniq
      staves.first if staves.length == 1
    end

    def read_clef(element)
      @opening_clef = ClefReading.clef(element, **@where, element: element) if @entries.empty? && @opening_clef.nil?
    end

    def value(element, name)
      AttributeValues.read(element, name, **@where, element: element)
    end
  end
end
