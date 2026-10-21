module HeadMusic::MIDI
  # Renders a flow as a format 1 Standard MIDI File: a conductor track, then
  # one track per part. Every time is an exact Rational until the tick
  # resolution is chosen, and every error is raised before any bytes exist.
  class Writer
    attr_reader :flow, :transposed

    def initialize(flow, transposed: false)
      @flow = flow
      @transposed = transposed
    end

    def to_s
      @preflight = Preflight.new(flow, transposed: transposed).check
      @timeline = PerformanceTimeline.new(flow, @preflight.played_bars)
      @resolution = TickResolution.new(times)
      SMF.file(division: @resolution.division, tracks: tracks)
    end

    private

    def part_tracks
      @part_tracks ||= begin
        lyric_events = LyricEvents.new(flow)
        flow.parts.map do |part|
          channel = @preflight.channels.channel_for(part)
          PartTrack.new(part, timeline: @timeline, channel: channel, transposed: transposed, lyric_events: lyric_events)
        end
      end
    end

    def conductor_events
      @conductor_events ||= ConductorTrack.new(flow, @timeline, @preflight.tempo_steps).events
    end

    def meta_events
      @meta_events ||= part_tracks.map(&:meta_events)
    end

    def times
      [
        @timeline.finish, *@timeline.spans.map(&:start), *conductor_events.map(&:tick), *meta_events.flatten.map(&:tick),
        *part_tracks.flat_map(&:notes).flat_map { |note| [note.on, note.off] }
      ]
    end

    def tracks
      tracks = [conductor_events, *meta_events].map { |events| events.map { |event| event.with(tick: @resolution.ticks(event.tick)) } }
      KeyOverlaps.new(soundings).events.each { |track, event| tracks[track] << event }
      finish = [@resolution.ticks(@timeline.finish), *tracks.flatten.map(&:tick)].max
      @preflight.check_ticks(finish, @resolution.division)
      tracks.each { |events| events << EndOfTrack.new(finish) }
    end

    def soundings
      part_tracks.each_with_index.flat_map do |part_track, index|
        part_track.notes.map do |note|
          on, off = @resolution.note_ticks(note.on, note.off)
          KeyOverlaps::Sounding.new(index + 1, note.channel, note.key, on, off, note.velocity)
        end
      end
    end
  end
end
