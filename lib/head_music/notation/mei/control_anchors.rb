module HeadMusic::Notation::MEI
  # Resolves where each event and control event of a score is, once its
  # voices are placed, and answers the mark readers' questions about the
  # score, so that no reader touches the id index.
  #
  # A control's end by id is the event its @startid or @endid names; ids win
  # over beats. One by beat is the onset its @tstamp falls within 1/1000
  # beat of, in the layer its @staff and @layer name, else on that staff,
  # and otherwise the position rounded from the exact offset of
  # (tstamp - 1) / meter.unit into its measure. A @tstamp2 of "Nm+b" counts
  # N measures on; one at or past the end of the music, as the beat after
  # the last bar's count, is the final barline. A @tstamp2 with no measure
  # part, and a span by beats that ends before it starts, have no finish.
  #
  # A reference into another file, or into a reading the editorial rule
  # rejects, skips its control; one naming no element, or an xml:id used
  # twice, raises.
  class ControlAnchors
    include XmlReading

    CONTAINERS = %w[beam tuplet graceGrp bTrem fTrem].freeze

    def initialize(flow, score, bar_map, source, parts, voices)
      @flow = flow
      @score = score
      @bar_map = bar_map
      @index = source.index
      @editorial = source.editorial
      @parts = parts
      @voices = voices
      @event_records = {}.compare_by_identity
      @onsets = OnsetIndex.new(score.readings)
    end

    # The record of a Pending, made once.
    def event_record(pending)
      @event_records[pending] ||= build_event_record(pending)
    end

    # The anchor at an event's record: where it sounds, its own link's
    # position for a tie's later link.
    def anchor(record)
      position = record_position(record)
      position && Anchor.new(position: position, voice: record.voice, voice_event: record.voice_event, grace_index: record.grace_index, record: record)
    end

    # A control's record, or nil where it is skipped.
    def control_record(control, measure)
      where = {measure: measure.number, element: control}
      references = %w[startid endid].to_h { |name| [name, reference(control, name, where)] }
      plist = attribute(control, "plist", **where).to_s.split.map { |item| @index.resolve(item, **where) }
      return if references.value?(:skip) || plist.include?(nil)

      staff = AttributeValues.read(control, "staff", **where)
      layer = AttributeValues.read(control, "layer", **where)
      start = end_anchor(references["startid"]) { start_by_beat(control, measure, staff, layer, where) }
      finish = end_anchor(references["endid"]) { finish_by_beat(control, measure, staff, layer, where) }
      finish = nil if finish && start && references.values.none? && finish.position < start.position
      ControlRecord.new(
        part: part_for(staff) || start&.record&.part, voice: voice_for(staff, layer), bar_number: @bar_map.bar_number(measure.index),
        measure: measure.number, element: control, start: start, finish: finish,
        plist: plist.filter_map { |element| record_for(element) }.filter_map { |record| anchor(record) }
      )
    end

    # The voice that a staff's layer is read as, or nil.
    def voice_for(staff, layer)
      return unless staff && layer

      reading = reading_for(staff)
      track = reading&.layer_track(staff, layer)
      track && @voices[track]
    end

    def part_for(staff)
      reading = staff && reading_for(staff)
      reading && @parts[reading]
    end

    # The records of the notes and chords that start where an anchor is, as
    # a span by beats asks that exactly one does.
    def notes_starting_at(anchor)
      starts.fetch(anchor.position.to_a, [])
    end

    # The <beam>, <tuplet>, <graceGrp>, <bTrem>, and <fTrem> an event is
    # inside in its layer, outermost first, through any editorial markup
    # between them.
    def containers(record)
      found = []
      element = record.element.parent
      while element.is_a?(REXML::Element) && element.name != "layer"
        found.unshift(element) if CONTAINERS.include?(element.name)
        element = element.parent
      end
      found
    end

    # An element's children and text as the editorial rule reads them.
    def children(element)
      @editorial.children(element)
    end

    def children_named(element, name)
      @editorial.children_named(element, name)
    end

    def text(element)
      @editorial.text(element)
    end

    private

    def build_event_record(pending)
      grace = pending.grace
      event = grace ? grace.event : pending.event
      voice = @voices[pending.track]
      voice_event, onset = event ? placed(event, voice) : [nil, nil]
      dropped = grace && (voice_event.nil? || voice_event.rest? || event.continuation)
      EventRecord.new(
        part: @parts[pending.reading], voice: voice, voice_event: dropped ? nil : voice_event, kind: pending.kind,
        chord_member: pending.chord_member, grace: !grace.nil?,
        grace_index: (grace && !dropped) ? event.graces.index { |candidate| candidate.equal?(grace) } : nil,
        continuation: !grace && !event&.continuation.nil?, bar_number: @bar_map.bar_number(event&.measure_index || pending.measure_index),
        onset: onset, measure: @score.measures[pending.measure_index].number, staff: pending.content.staff_number, element: pending.element
      )
    end

    # The voice event an event was placed as, and the exact offset into its
    # bar where it sounds. A whole-bar rest is the rest at the start of its
    # bar, if the voice is placed there.
    def placed(event, voice)
      bar = @bar_map.bar_number(event.measure_index)
      return [voice.voice_event_at(@flow.position(bar, 1, 0)), 0] if event.fills_bar

      head = event.head
      return [nil, nil] unless head.time

      time = head.time + head.rhythmic_value.tied_chain.take(event.first_link).sum(&:link_fraction)
      [head.voice_event, time - @bar_map.start(bar)]
    end

    def record_position(record)
      return record.voice_event.position if record.voice_event && !record.continuation?
      return unless record.onset

      position_in(record.bar_number, record.onset)
    end

    # The element a reference names, nil where there is none, or :skip.
    def reference(control, name, where)
      value = attribute(control, name, **where)
      return unless value

      @index.resolve(value, **where) || :skip
    end

    # By its element, unless that is no event a voice reads; else by beat.
    def end_anchor(element)
      record = element && record_for(element)
      record ? anchor(record) : yield
    end

    def record_for(element)
      pending = pending_by_element[element]
      pending&.track && event_record(pending)
    end

    def start_by_beat(control, measure, staff, layer, where)
      beat = Tstamp.start(control, measure, **where)
      beat && at_beat(measure.index, beat, staff, layer)
    end

    def finish_by_beat(control, measure, staff, layer, where)
      index, beat = Tstamp.finish(control, @score.measures, measure.index, **where)
      index && at_beat(index, beat, staff, layer)
    end

    def at_beat(index, beat, staff, layer)
      meter = @score.measures[index].meter
      offset = Tstamp.offset(beat, meter)
      return final_barline if @bar_map.time_of(index, offset) >= @bar_map.end_time

      record = staff && snapped(index, offset, meter, staff, layer)
      return anchor(record) if record

      position = position_in(@bar_map.bar_number(index), @bar_map.shift(index) + offset)
      Anchor.new(position: position, voice: voice_for(staff, layer), voice_event: nil, grace_index: nil, record: nil)
    end

    def snapped(index, offset, meter, staff, layer)
      @onsets.at(index, offset, meter.bottom_number, staff: staff, layer: layer)
        .lazy.filter_map { |onset| onset.pending.first.track && event_record(onset.pending.first) }.first
    end

    def final_barline
      Anchor.new(position: @flow.final_barline_position, voice: nil, voice_event: nil, grace_index: nil, record: nil)
    end

    # An offset at or past its bar's end is the next bar's start.
    def position_in(bar_number, offset)
      meter = @flow.meter_at(bar_number)
      return @flow.position(bar_number + 1, 1, 0) if offset >= Rational(meter.top_number, meter.bottom_number)

      HeadMusic::Notation::BarSplitter.position_at(@flow, bar_number, offset)
    end

    def reading_for(staff)
      @readings_by_staff ||= {}
      @readings_by_staff.fetch(staff) do
        @readings_by_staff[staff] = @score.readings.find { |reading| reading.definition.staff_index(staff) }
      end
    end

    def pending_by_element
      @pending_by_element ||= @score.pending.each_with_object({}.compare_by_identity) { |pending, by_element| by_element[pending.element] = pending }
    end

    def starts
      @starts ||= @event_records.each_value.with_object({}) do |record, starts|
        next unless record.note? && record.voice_event && !record.grace? && !record.continuation? && !record.chord_member?

        (starts[record.voice_event.position.to_a] ||= []) << record
      end
    end
  end
end
