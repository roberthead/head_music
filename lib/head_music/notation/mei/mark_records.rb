module HeadMusic::Notation::MEI
  # The records the core hands each mark reader once every voice is final:
  # placed, padded, tied, grouped, and on its staves. Each carries its REXML
  # element and its measure's @n, for messages. MarkRecords lists them in
  # document order, each measure's MeasureRecord first, then the
  # EventRecords of its staves, then the ControlRecords of its controls.
  #
  # EventRecord, one per <note>, <chord>, <rest>, <mRest>, and <space> that
  # a voice reads; +kind+ is :note, :chord, :rest, :m_rest, or :space. Its
  # voice event is the note or rest it was placed as: for a chord tone, the
  # chord; for a tie's later link (a continuation), the event its chain
  # began with; for a whole-bar rest, the rest its bar was filled with, nil
  # in a bar the voice is tacet in; for a grace note, the main note it led
  # to, at grace_index among that note's grace notes, or nil where it was
  # dropped, as before a rest. The onset is the exact fraction of a whole
  # note from the start of its bar to where it sounds, a continuation's
  # being its own link's. +staff+ is the @n of the <staff> its layer is in.
  EventRecord = Data.define(
    :part, :voice, :voice_event, :kind, :chord_member, :grace, :grace_index, :continuation,
    :bar_number, :onset, :measure, :staff, :element
  ) do
    alias_method :chord_member?, :chord_member
    alias_method :grace?, :grace
    alias_method :continuation?, :continuation

    # A note or chord, rather than a rest or space.
    def note?
      %i[note chord].include?(kind)
    end

    # The note or chord a mark attaches to, nil for a rest, a grace note, or
    # a tie's later link.
    def markable_event
      voice_event if note? && !grace? && !continuation? && voice_event && !voice_event.rest?
    end
  end

  # Where a control event's end is: a position, and the voice, voice event,
  # and grace note there where it names or snaps to one, with that event's
  # record. At the final barline it has a position alone.
  Anchor = Data.define(:position, :voice, :voice_event, :grace_index, :record) do
    def bar_number
      position.bar_number
    end

    # Whether it is at an event rather than only at a time.
    def event?
      !record.nil?
    end
  end

  # ControlRecord, one per child of a <measure> other than its staves, as
  # <slur>, <dynam>, <hairpin>, or <dir>, in document order. Its +part+ and
  # +voice+ are those its @staff (the first of a list such as "1 2") and
  # @layer name, each nil where it names none. +start+ and +finish+ are its
  # resolved Anchors, ids winning over beats, nil where it states neither,
  # where a @tstamp2 has no measure part, or where a span by beats ends
  # before it starts; +plist+ the Anchors its @plist lists. A control whose
  # reference points into another file or into a reading the editorial rule
  # rejects has no record.
  ControlRecord = Data.define(:part, :voice, :bar_number, :measure, :element, :start, :finish, :plist) do
    # Whether it has both ends.
    def span?
      !start.nil? && !finish.nil?
    end
  end

  # MeasureRecord, one per <measure>. +last+ says it is in the last bar;
  # +ending_passes+ are the passes of the <ending> it is in, or nil; and
  # +mid_bar+ says its right barline falls inside a bar, as that of a
  # measure that the next one completes, whose record has the same
  # bar_number.
  MeasureRecord = Data.define(:bar_number, :measure, :element, :last, :ending_passes, :mid_bar) do
    include HeadMusic::Notation::BarlinePlacement
  end

  # Builds every record of a score once its voices are placed.
  class MarkRecords
    EVENT_KINDS = %i[note chord rest m_rest space].freeze

    def initialize(score, bar_map, anchors)
      @score = score
      @bar_map = bar_map
      @anchors = anchors
    end

    def records
      events = events_by_measure
      @score.measures.each_with_index.flat_map do |measure, index|
        [
          *measure_record(measure, index),
          *events.fetch(index, []),
          *measure.controls.filter_map { |control| @anchors.control_record(control, measure) }
        ]
      end
    end

    private

    def events_by_measure
      @score.pending.each_with_object({}) do |pending, events|
        next unless pending.track && EVENT_KINDS.include?(pending.kind)

        (events[pending.measure_index] ||= []) << @anchors.event_record(pending)
      end
    end

    # A <multiRest> stands for several measures of one element, and has one
    # record.
    def measure_record(measure, index)
      return [] if index.positive? && @score.measures[index - 1].element.equal?(measure.element)

      last_index = index
      last_index += 1 while @score.measures[last_index + 1]&.element.equal?(measure.element)
      [MeasureRecord.new(
        bar_number: @bar_map.bar_number(index), measure: measure.number, element: measure.element,
        last: @bar_map.bar_number(last_index) == @bar_map.last_bar,
        ending_passes: measure.ending_passes, mid_bar: @bar_map.split_before?(last_index + 1)
      )]
    end
  end
end
