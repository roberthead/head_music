# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # The records the core hands each mark reader, one per element, in
  # document order within each part, once every voice is final: placed,
  # padded, tied, grouped, and on its staves. Each carries its REXML element
  # and the measure's number attribute, for messages.
  #
  # NoteRecord, one per <note>. Its voice event is the note or rest it was
  # placed as: for a chord tone, the chord; for a tie's later link (a
  # continuation), the event its chain began with; for a whole-measure rest,
  # the rest its bar was filled with; for a grace note, the main note it led
  # to, at grace_index among that note's grace notes, or with a nil
  # grace_index where it was dropped, as before a rest. A grace note queued
  # at the end of a part has no voice event. The onset is the exact fraction
  # of a whole note from the start of its bar to where the note sounds, a
  # continuation's being its own link's.
  #
  # DirectionRecord, one per <direction>, and per <sound> written straight
  # in a measure. The cursor is the exact fraction of a whole note from the
  # start of its bar before any <offset>, and divisions those in force there,
  # nil before any. voice_for(label) answers the part's voice for a <voice>
  # value, or nil.
  #
  # BarlineRecord, one per <barline>. last? says it is in the last bar, and
  # mid_bar? that it falls inside a bar, as the right barline of a measure
  # that an implicit one completes does.
  NoteRecord = Data.define(:part, :voice, :voice_event, :grace, :grace_index, :chord, :continuation, :bar_number, :onset, :measure, :element) do
    alias_method :grace?, :grace
    alias_method :chord?, :chord
    alias_method :continuation?, :continuation
  end

  DirectionRecord = Data.define(:part, :bar_number, :cursor, :divisions, :measure, :element, :voices) do
    def voice_for(label)
      voices[label.to_s.strip]
    end
  end

  BarlineRecord = Data.define(:part, :bar_number, :last, :mid_bar, :measure, :element) do
    alias_method :last?, :last
    alias_method :mid_bar?, :mid_bar
  end

  # Builds a part's records from what its reader noted as it walked.
  class MarkRecords
    # What the part reader notes of each element as it walks: for a note,
    # its event or grace note and whether it is a chord tone.
    Pending = Struct.new(:kind, :element, :measure_index, :event, :grace, :chord, :cursor, :divisions)

    def initialize(part, reading, bar_map, voices)
      @part = part
      @reading = reading
      @bar_map = bar_map
      @voices = voices.freeze
    end

    def records
      @reading.records.map do |pending|
        case pending.kind
        when :note then note_record(pending)
        when :direction then direction_record(pending)
        when :barline then barline_record(pending)
        end
      end
    end

    private

    def note_record(pending)
      event = pending.grace ? pending.grace.event : pending.event
      voice_event, onset = event ? placed(event) : [nil, nil]
      NoteRecord.new(
        part: @part, voice: @voices[pending.grace ? pending.grace.label : event.label], voice_event: voice_event,
        grace: !pending.grace.nil?, grace_index: grace_index(pending.grace, voice_event), chord: pending.chord,
        continuation: !event&.continuation.nil? && !pending.grace, bar_number: bar_of(event&.measure_index || pending.measure_index),
        onset: onset, measure: measure_number(pending), element: pending.element
      )
    end

    # A whole-measure rest is the rest at the start of its bar.
    def placed(event)
      bar = bar_of(event.measure_index)
      return [voice_for(event).voice_event_at(@part.flow.position(bar, 1, 0)), 0] if event.fills_bar

      head = event.head
      time = head.time + head.rhythmic_value.tied_chain.take(event.first_link).sum(&:link_fraction)
      [head.voice_event, time - @bar_map.start(bar)]
    end

    def voice_for(event)
      @voices.fetch(event.label)
    end

    def grace_index(grace, voice_event)
      return unless grace && voice_event && !voice_event.rest? && !grace.event.continuation

      grace.event.graces.index { |candidate| candidate.equal?(grace) }
    end

    def direction_record(pending)
      DirectionRecord.new(
        part: @part, bar_number: bar_of(pending.measure_index), cursor: @bar_map.shift(pending.measure_index) + pending.cursor,
        divisions: pending.divisions, measure: measure_number(pending), element: pending.element, voices: @voices
      )
    end

    def barline_record(pending)
      index = pending.measure_index
      location = XmlReading.attribute(pending.element, "location") || "right"
      BarlineRecord.new(
        part: @part, bar_number: bar_of(index), last: bar_of(index) == @bar_map.last_bar,
        mid_bar: (location == "right") ? @bar_map.split_before?(index + 1) : (location == "left" && @bar_map.split_before?(index)),
        measure: measure_number(pending), element: pending.element
      )
    end

    def bar_of(measure_index)
      @bar_map.bar_number(measure_index)
    end

    def measure_number(pending)
      @reading.measures[pending.measure_index].number
    end
  end
end
