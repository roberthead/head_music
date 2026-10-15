# A module for visual music notation
module HeadMusic::Notation
  # Places one track's events on its voice in order, each at the position
  # the one before it ends, with rests split at barlines across any gap and
  # out to the end of the music, so every voice spans the whole flow.
  #
  # Two clocks meet here: the exact time each event was read at, from the
  # durations before it, and the exact time the voice's written values
  # reach. Within one division they are the same time, and the gap is
  # exporter rounding; beyond it, a later event leaves a rest and an earlier
  # one overlaps the voice.
  class VoicePlacer
    def initialize(voice, track, bar_map, reading, tuplet_reader:)
      @voice = voice
      @track = track
      @bar_map = bar_map
      @reading = reading
      @tuplet_reader = tuplet_reader
    end

    def place
      @time = @bar_map.start(@bar_map.first_bar)
      @position = @voice.flow.position(@bar_map.first_bar, 1, 0)
      @track.events.each { |event| place_event(event) unless event.fills_bar || event.continuation }
      rest_until(@bar_map.end_time, nil)
      @tuplet_reader.new(@voice, @track, @reading).group
      assign_staves
    end

    private

    def place_event(event)
      time = @bar_map.time_of(event.measure_index, event.cursor)
      gap = time - @time
      if gap >= event.tolerance
        rest_until(time, event)
      elsif gap <= -event.tolerance
        raise @reading.errors::ParseError.new("Voice #{@track.label} overlaps itself", **where(event))
      end
      event.time = @time
      voice_event = event.voice_event = @voice.place(@position, event.rhythmic_value, event.sounds)
      add_grace_notes(voice_event, event.graces)
      @position = voice_event.next_position
      @time += event.rhythmic_value.fraction
    end

    # Grace notes before a rest, or before a tie's later link, which is
    # never placed, are dropped.
    def add_grace_notes(voice_event, graces)
      return if voice_event.rest?

      graces.each do |grace|
        voice_event.add_grace_note(
          grace.sounds, grace.rhythmic_value, slashed: grace.slashed, tied: grace.tied, articulations: grace.articulations
        )
      end
    end

    def rest_until(time, event)
      while @time < time
        segment_end = [@bar_map.next_bar_start(@time), time].compact.min
        value = HeadMusic::Notation::DottedDuration.rest_value(segment_end - @time)
        raise @reading.errors::UnsupportedFeatureError.new("No rest fills the gap in voice #{@track.label}", **where(event)) unless value

        @position = @voice.place(@position, value).next_position
        @time = segment_end
      end
    end

    # A voice is on the staff of its first event in each bar, crossing at
    # the barlines where that changes; a change in the middle of a bar is
    # skipped, since the model crosses only at barlines.
    def assign_staves
      staves = @voice.part.staff_system.staves
      return if staves.length < 2

      current = staves.first
      @track.events.chunk_while { |before, after| bar_of(before) == bar_of(after) }.each_with_index do |events, index|
        staff = staves[events.first.staff - 1]
        next if staff.equal?(current)

        @voice.assign_staff(index.zero? ? @bar_map.first_bar : bar_of(events.first), staff)
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
