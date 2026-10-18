module HeadMusic::Notation::MEI
  # The EventRecord of each Pending once its voice is placed, made once, and
  # the records made of the notes and chords that start at a position.
  class EventRecords
    def initialize(flow, score, bar_map, parts, voices)
      @flow = flow
      @score = score
      @bar_map = bar_map
      @parts = parts
      @voices = voices
      @records = {}.compare_by_identity
    end

    def [](pending)
      @records[pending] ||= build(pending)
    end

    def starting_at(position)
      starts.fetch(position.to_a, [])
    end

    private

    def build(pending)
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

      time = head.time + event.link_start
      [head.voice_event, time - @bar_map.start(bar)]
    end

    def starts
      @starts ||= @records.each_value.with_object({}) do |record, starts|
        next unless record.note? && record.voice_event && !record.grace? && !record.continuation? && !record.chord_member?

        (starts[record.voice_event.position.to_a] ||= []) << record
      end
    end
  end
end
