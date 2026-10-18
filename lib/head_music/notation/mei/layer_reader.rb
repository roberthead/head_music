module HeadMusic::Notation::MEI
  # Reads one <layer> into entries in document order, each at the cursor it
  # starts at, an exact fraction of a whole note from the start of the
  # measure. Containers are walked through: <beam>, <tuplet>, <graceGrp>,
  # <bTrem>, whose note or chord reads alone, and <fTrem>, whose members
  # read in sequence at their own @dur. The tremolo itself is skipped.
  #
  # A <note> or <chord> takes its duration as DurationReading reads it. A
  # <tuplet>, or a <tupletSpan> through TupletSpans, scales the entries in
  # it, and each is a run to group. A grace note takes no time and no
  # tuplet ratio. A @cue note is a rest, and a cue grace note is dropped. <rest> and <space> are rests of their length, one of none
  # taking what OpenSpaces gives it, and <mRest>, <mSpace>, and
  # <multiRest> fill their bars. LayerSigns reads its <clef>s and <keySig>.
  # <barLine> and every element the reader does not use are skipped.
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
    # the clefs it opens and closes with, if any, and the key it opens
    # with, as a ScoreDefValues::Key. +occurrence+ counts
    # the layers with notes before it in the bar that share its staff and
    # @n.
    Content = Struct.new(:number, :element, :staff_number, :entries, :extent, :opening_clef, :closing_clef, :occurrence, :opening_key) do
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
    Context = Data.define(:grace, :slashed, :ratio, :run)
    PLAIN = Context.new(grace: false, slashed: false, ratio: nil, run: nil)

    REPEATS = %w[mRpt mRpt2 beatRpt halfmRpt multiRpt].freeze
    CONTAINERS = %w[beam tuplet bTrem fTrem].freeze
    MAX_DEPTH = 2 * Editorial::MAX_DEPTH

    def initialize(layer, editorial, staff_number:, tuplets:, duration_default: nil, **where)
      @layer = layer
      @editorial = editorial
      @staff_number = staff_number
      @tuplets = tuplets
      @where = where
      @durations = DurationReading.new(editorial, duration_default, **where)
      @number = AttributeValues.read(layer, "n", **where, element: layer) || 1
      @cursor = 0
      @extent = nil
      @entries = []
      @signs = LayerSigns.new(**where)
    end

    def read
      walk(@layer, PLAIN, 1)
      Content.new(
        number: @number, element: @layer, staff_number: @staff_number, entries: @entries, extent: @extent,
        opening_clef: @signs.opening_clef, closing_clef: @signs.closing_clef(@entries.length), occurrence: 0, opening_key: @signs.opening_key
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
      when "chord" then add_sounding(:chord, child, chord_notes(child), context)
      when "rest", "space" then add_rest(child, context)
      when "mRest" then add_fill(:m_rest, child)
      when "mSpace" then add_fill(:m_space, child)
      when "multiRest" then add_fill(:multi_rest, child, bars: value(child, "num") || 1)
      when "graceGrp" then walk(child, grace_context(child, context), depth + 1)
      when *CONTAINERS then walk(child, container_context(child, context), depth + 1)
      when "clef" then @signs.clef(child, @entries.length)
      when "keySig" then @signs.key_sig(child, @entries.length)
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

      add_timed(element, notes, context, kind: kind, notes: notes, cue: cue, staff: staff_of(element, notes))
    end

    def add_grace(kind, element, notes, context)
      slashed = value(element, "grace")
      @entries << entry(
        element, kind: kind, notes: notes, rhythmic_value: @durations.rhythmic_value(element, grace: true),
        grace: true, slashed: slashed.nil? ? context.slashed : slashed, staff: staff_of(element, notes)
      )
    end

    def add_rest(element, context)
      return @entries << entry(element) if @durations.open?(element)

      add_timed(element, [], context)
    end

    def add_fill(kind, element, bars: 1)
      @entries << entry(element, kind: kind, bars: bars)
    end

    # A note, chord, or rest that takes time, joining the tuplets around it.
    def add_timed(element, notes, context, **fields)
      span = @tuplets.enter(stream, [element, *notes], @where.merge(element: element))
      rhythmic = @durations.rhythmic_value(element, ratio: ratio(context, span, element))
      advance(entry(element, rhythmic_value: rhythmic, duration: rhythmic.fraction, **fields), context, span)
    end

    def entry(element, **fields)
      Entry.new(kind: element.name.to_sym, element: element, notes: [], cursor: @cursor, grace: false, cue: false, **fields)
    end

    def stream
      [@staff_number, @number]
    end

    # A container inside a span of its ratio is absorbed into it.
    def ratio(context, span, element)
      TupletSpans.nested(**@where, element: element) if span && context.ratio && span.ratio != context.ratio
      context.ratio || span&.ratio
    end

    def advance(entry, context, span)
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

    # A chord's @staff, else the one its notes share.
    def staff_of(element, notes)
      staff = value(element, "staff")
      return staff if staff

      staves = notes.map { |note| value(note, "staff") }.uniq
      staves.first if staves.length == 1
    end

    def value(element, name)
      AttributeValues.read(element, name, **@where, element: element)
    end
  end
end
