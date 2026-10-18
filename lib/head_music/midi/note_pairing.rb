module HeadMusic::MIDI
  # Pairs each note off with the earliest sounding note on of its channel and
  # key across every track, since a writer may release a note in another
  # track. A note never released ends at its own track's last tick.
  class NotePairing
    def initialize(sequence)
      @sequence = sequence
      @notes = Array.new(sequence.tracks.length) { [] }
      @held = Hash.new { |hash, key| hash[key] = [] }
    end

    # The sequence with each track's notes.
    def sequence
      @paired ||= begin
        pair
        tracks = @sequence.tracks.zip(@notes).map { |track, notes| Reader::Track.new(track.events, track.terminated, Reader.sorted(notes)) }
        Reader::Sequence.new(@sequence.format, @sequence.division, tracks)
      end
    end

    private

    def pair
      @sequence.indexed_events.each do |track_index, event|
        case event
        when NoteOn then held(event) << [track_index, event]
        when NoteOff then release(held(event).shift, event.tick)
        end
      end
      @held.each_value { |queue| queue.each { |sounding| release(sounding, end_tick(sounding.first)) } }
    end

    def held(event)
      @held[[event.channel, event.key]]
    end

    def end_tick(track_index)
      @sequence.tracks[track_index].events.last&.tick || 0
    end

    def release(sounding, tick)
      return unless sounding

      track_index, on = sounding
      @notes[track_index] << Reader::Note.new(on.channel, on.key, on.velocity, on.tick, tick, track_index)
    end
  end
end
