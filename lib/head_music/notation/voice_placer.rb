# A module for visual music notation
module HeadMusic::Notation
  # Places one track's events on its voice in order, each at the position
  # the one before it ends, with rests split at barlines across any gap and
  # out to the end of the music, so every voice spans the whole flow. With
  # +trim_edges:+, a voice instead spans the bars from its first placed
  # event's to its last's, padded to the end of that bar, so that the
  # whole-bar rests at its edges are absence, as MEI writes a tacet voice.
  #
  # Two clocks meet here: the exact time each event was read at, from the
  # durations before it, and the exact time the voice's written values
  # reach. Within one division they are the same time, and the gap is
  # exporter rounding; beyond it, a later event leaves a rest and an earlier
  # one overlaps the voice.
  class VoicePlacer
    def initialize(voice, track, bar_map, reading, tuplet_reader:, trim_edges: false)
      @voice = voice
      @track = track
      @bar_map = bar_map
      @reading = reading
      @tuplet_reader = tuplet_reader
      @trim_edges = trim_edges
    end

    def place
      events = @track.events
      placed = events.reject { |event| event.fills_bar || event.continuation }
      return assign_staves(events) if @trim_edges && placed.empty?

      start_at(@trim_edges ? bar_of(placed.first) : @bar_map.first_bar)
      placed.each { |event| place_event(event) }
      rest_until(@trim_edges ? @bar_map.bar_end_at_or_after(@time) : @bar_map.end_time, nil)
      @tuplet_reader.new(@voice, @track, @reading).group
      assign_staves(@trim_edges ? events[..events.index(placed.last)] : events)
    end

    private

    def start_at(bar)
      @time = @bar_map.start(bar)
      @position = @voice.flow.position(bar, 1, 0)
    end

    def place_event(event)
      time = @bar_map.time_of(event.measure_index, event.cursor)
      gap = time - @time
      if gap >= event.tolerance
        rest_until(time, event)
      elsif gap <= -event.tolerance
        raise @reading.errors::ParseError.new("Voice #{@track.label} overlaps itself", **where(event))
      end
      event.time = @time
      @position = event.place_on(@voice, @position).next_position
      @time += event.rhythmic_duration.fraction
    end

    def rest_until(time, event)
      while @time < time
        segment_end = [@bar_map.next_bar_start(@time), time].compact.min
        rest = HeadMusic::Notation::DottedDuration.rest_duration(segment_end - @time)
        raise @reading.errors::UnsupportedFeatureError.new("No rest fills the gap in voice #{@track.label}", **where(event)) unless rest

        @position = @voice.place(@position, rest).next_position
        @time = segment_end
      end
    end

    # A voice is on the staff of its first event in each bar, crossing at
    # the barlines where that changes; a change in the middle of a bar is
    # skipped, since the model crosses only at barlines. The whole-bar rests
    # of a voice's trimmed opening still say which staff it opens on.
    def assign_staves(events)
      staves = @voice.part.staff_system.staves
      return if staves.length < 2

      current = staves.first
      events.chunk { |event| bar_of(event) }.each_with_index do |(bar, bar_events), index|
        staff = staves[bar_events.first.staff - 1]
        next if staff.equal?(current)

        @voice.assign_staff(index.zero? ? @bar_map.first_bar : bar, staff)
        current = staff
      end
    end

    def bar_of(event)
      @bar_map.bar_number(event.measure_index)
    end

    def where(event)
      @reading.where(event&.measure_index)
    end
  end
end
