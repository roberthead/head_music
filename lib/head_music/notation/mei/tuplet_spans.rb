module HeadMusic::Notation::MEI
  # The tuplets of a score as its layers are read: <tuplet> containers,
  # <tupletSpan> control events, and runs from @tuplet i to t. Each is a run
  # of entries that becomes one group once the voices are known.
  #
  # A span by @plist scales its members; one by @startid and @endid scales
  # every entry from its start to its end in the layer it starts in, across
  # barlines. One placed only by beats scales nothing. A container inside a
  # span of its ratio is absorbed into it, as MEI Export hides a bracket's
  # portion in each bar, and one of another ratio is a nested tuplet, which
  # raises. @tuplet names no ratio, so its run groups only entries that a
  # container or span scales alike.
  class TupletSpans
    include XmlReading

    Run = Struct.new(:ratio, :entries)
    Span = Struct.new(:ratio, :last, :run)

    # The ratio of a <tuplet> or <tupletSpan>, from @num and @numbase. An
    # odd @num alone is in the time of the power of two below it, as 3 is
    # in the time of 2; any other gives none, nor does @num equal to
    # @numbase.
    def self.ratio(element, **where)
      num = AttributeValues.read(element, "num", **where, element: element)
      numbase = AttributeValues.read(element, "numbase", **where, element: element)
      numbase ||= 1 << ((num - 1).bit_length - 1) if num&.odd? && num > 1
      HeadMusic::Rudiment::TupletRatio.get([num, numbase]) if num && numbase && num != numbase
    end

    def self.nested(**where)
      raise UnsupportedFeatureError.new("Nested tuplets are not supported", **where)
    end

    def initialize(index)
      @index = index
      @starts = {}.compare_by_identity
      @members = {}.compare_by_identity
      @open = {}
      @marked = {}
      @runs = []
    end

    # Notes the <tupletSpan>s of a measure before its layers are read.
    def note_controls(controls, where)
      controls.each { |control| add_span(control, where.merge(element: control)) if control.name == "tupletSpan" }
    end

    def add_run(run)
      @runs << run
    end

    # The span an entry of these elements is in, in a layer stream: one
    # whose @plist lists it, or one it starts, ends, or falls between the
    # ends of.
    def enter(stream, elements, where)
      listed = elements.lazy.filter_map { |element| @members[element] }.first
      return listed if listed

      span = open_span(stream, elements, where)
      @open.delete(stream) if span && elements.any? { |element| element.equal?(span.last) }
      span
    end

    # Each timed entry of a layer stream, with its @tuplet, if any: i opens
    # a run that every entry joins until t closes it.
    def mark(stream, marker, entry)
      @marked[stream] = Run.new(nil, []) if marker == "i"
      run = @marked[stream]
      return unless run

      run.entries << entry
      add_run(@marked.delete(stream)) if marker == "t"
    end

    # By track, the first and last events of each group, once the voices
    # are assigned. A run any of whose entries no voice reads, or that two
    # voices share, groups nothing.
    def groups
      owners = {}.compare_by_identity
      by_track = {}.compare_by_identity
      largest_first.each do |run|
        ratio = run_ratio(run)
        next unless ratio && placed?(run) && !absorbed?(run, ratio, owners)

        run.entries.each { |entry| owners[entry] ||= [run, ratio] }
        (by_track[run.entries.first.track] ||= []) << [run.entries.first.event, run.entries.last.event]
      end
      by_track
    end

    private

    def add_span(control, where)
      ratio = self.class.ratio(control, **where)
      return unless ratio

      span = Span.new(ratio, named(control, "endid", where), Run.new(ratio, []))
      plist = attribute(control, "plist", **where)
      if plist
        plist.split.each do |reference|
          member = @index.named(reference, **where)
          @members[member] = span if member
        end
      else
        start = named(control, "startid", where)
        @starts[start] = span if start && span.last
      end
      add_run(span.run)
    end

    def named(control, name, where)
      reference = attribute(control, name, **where)
      reference && @index.named(reference, **where)
    end

    def open_span(stream, elements, where)
      span = @open[stream]
      starting = elements.lazy.filter_map { |element| @starts[element] }.first
      return span unless starting

      self.class.nested(**where) if span
      @open[stream] = starting
    end

    def largest_first
      @runs.each_with_index.sort_by { |run, index| [-run.entries.length, index] }.map(&:first)
    end

    def run_ratio(run)
      return if run.entries.empty?
      return run.ratio if run.ratio

      ratios = run.entries.map { |entry| entry.rhythmic_value&.tuplet_ratio }.uniq
      ratios.first if ratios.one?
    end

    def placed?(run)
      track = run.entries.first.track
      track && run.entries.all? { |entry| entry.event && entry.track.equal?(track) }
    end

    def absorbed?(run, ratio, owners)
      owner, owner_ratio = owners[run.entries.first]
      owner && owner_ratio == ratio && run.entries.all? { |entry| owners[entry]&.first.equal?(owner) }
    end
  end
end
