# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Places one track's events on its voice in order, each at the position
  # the one before it ends, with rests split at barlines across any gap and
  # out to the end of the music, so every voice spans the whole flow.
  #
  # Two clocks meet here: the exact time each event was read at, from the
  # <duration>s before it, and the exact time the voice's written values
  # reach. Within one division they are the same time, and the gap is
  # exporter rounding; beyond it, a later event leaves a rest and an earlier
  # one overlaps the voice.
  class VoicePlacer
    def initialize(voice, track, bar_map, reading)
      @voice = voice
      @track = track
      @bar_map = bar_map
      @reading = reading
    end

    def place
      @time = @bar_map.start(@bar_map.first_bar)
      @position = @voice.flow.position(@bar_map.first_bar, 1, 0)
      @track.events.each { |event| place_event(event) unless event.fills_bar || event.continuation }
      rest_until(@bar_map.end_time, nil)
      TupletReader.new(@voice, @track, @reading).group
    end

    private

    def place_event(event)
      time = @bar_map.time_of(event.measure_index, event.cursor)
      gap = time - @time
      if gap >= event.tolerance
        rest_until(time, event)
      elsif gap <= -event.tolerance
        raise ParseError.new("Voice #{@track.label} overlaps itself", **where(event))
      end
      voice_event = event.voice_event = @voice.place(@position, event.rhythmic_value, event.sounds)
      @position = voice_event.next_position
      @time += event.rhythmic_value.fraction
    end

    def rest_until(time, event)
      while @time < time
        segment_end = [@bar_map.next_bar_start(@time), time].compact.min
        value = HeadMusic::Notation::DottedDuration.rest_value(segment_end - @time)
        raise UnsupportedFeatureError.new("No rest fills the gap in voice #{@track.label}", **where(event)) unless value

        @position = @voice.place(@position, value).next_position
        @time = segment_end
      end
    end

    def where(event)
      {measure: event && @reading.measures[event.measure_index]&.number, part: @reading.id}
    end
  end
end
