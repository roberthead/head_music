# Decodes a Standard MIDI File of format 0 or 1 into the writer's event value
# objects. It reads what other tools write as well as what the writer writes:
# running status, a note on at velocity 0 as a note off, unknown chunks, and
# tracks with no end-of-track. Events a flow cannot hold are skipped.
class HeadMusic::MIDI::Reader
  MAX_BYTES = 16 * 1024 * 1024
  MAX_EVENTS = 1_000_000
  MAX_WHOLE_NOTES = 10_000

  # +track+ is the index of the track holding the note on.
  Note = Data.define(:channel, :key, :velocity, :on, :off, :track) do
    def duration
      off - on
    end
  end

  # +terminated+ is false for a track that ends without an end-of-track event.
  Track = Data.define(:events, :terminated, :notes) do
    def initialize(events:, terminated:, notes: [])
      super(events: events.freeze, terminated: terminated, notes: notes.freeze)
    end

    def of(kind)
      events.grep(kind)
    end

    def name
      text(:sequence_name, :track_name)
    end

    # The first text of any of the kinds.
    def text(*kinds)
      events.find { |event| event.is_a?(HeadMusic::MIDI::Text) && kinds.include?(event.kind) }&.text
    end

    def lyrics
      events.select { |event| event.is_a?(HeadMusic::MIDI::Text) && event.kind == :lyric }
    end

    def program_changes
      of(HeadMusic::MIDI::ProgramChange)
    end
  end

  Sequence = Data.define(:format, :division, :tracks) do
    def initialize(format:, division:, tracks:)
      super(format: format, division: division, tracks: tracks.freeze)
    end

    def name
      tracks.first&.text(:sequence_name)
    end

    # Every track's events as a player merges them: by tick, then in track
    # order, keeping each track's own order within a tick.
    def merged_events
      indexed_events.map(&:last)
    end

    # [track index, event] pairs in merged order.
    def indexed_events
      tracks.each_with_index.flat_map { |track, track_index|
        track.events.each_with_index.map { |event, index| [event.tick, track_index, index, event] }
      }.sort_by { |tick, track_index, index, _event| [tick, track_index, index] }.map { |_tick, track_index, _index, event| [track_index, event] }
    end

    # Each track's notes, in its own order, then by track.
    def notes
      HeadMusic::MIDI::Reader.sorted(tracks.flat_map(&:notes))
    end
  end

  # By onset, channel and key, keeping the given order among equals.
  def self.sorted(notes)
    notes.each_with_index.sort_by { |note, index| [note.on, note.channel, note.key, index] }.map(&:first)
  end

  def initialize(bytes)
    raise ArgumentError, "expected a String of bytes, not #{bytes.class}" unless bytes.is_a?(String)

    @bytes = bytes.b
    @event_count = 0
  end

  def read
    raise HeadMusic::MIDI::ParseError.new("file is longer than #{MAX_BYTES} bytes", offset: MAX_BYTES) if @bytes.bytesize > MAX_BYTES

    @chunks = HeadMusic::MIDI::ChunkReader.new(@bytes)
    tracks = []
    @chunks.each_track { |start, limit| tracks << read_track(start, limit, tracks.length) }
    HeadMusic::MIDI::NotePairing.new(Sequence.new(@chunks.format, @chunks.division, tracks)).sequence
  end

  private

  def read_track(start, limit, index)
    reader = HeadMusic::MIDI::TrackReader.new(@bytes, start, limit, division: @chunks.division, events_before: @event_count)
    track = reader.track
    @event_count += reader.event_count
    index.zero? ? sequence_named(track) : track
  end

  # Format 1 writers that put notes in track 0 name a part there, not the piece.
  def sequence_named(track)
    return track unless @chunks.format.zero? || track.events.none?(HeadMusic::MIDI::NoteOn)

    events = track.events.map { |event| (event.is_a?(HeadMusic::MIDI::Text) && event.kind == :track_name) ? event.with(kind: :sequence_name) : event }
    Track.new(events, track.terminated)
  end
end
