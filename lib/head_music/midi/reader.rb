# Decodes a Standard MIDI File of format 0 or 1 into the writer's event value
# objects. It reads what other tools write as well as what the writer writes:
# running status, a note on at velocity 0 as a note off, unknown chunks, and
# tracks with no end-of-track. Events a flow cannot hold are skipped.
class HeadMusic::MIDI::Reader
  MAX_BYTES = 16 * 1024 * 1024
  MAX_EVENTS = 1_000_000
  MAX_WHOLE_NOTES = 10_000

  TEXT_KINDS = {
    0x01 => :text, 0x02 => :copyright, 0x03 => :track_name, 0x04 => :instrument_name,
    0x05 => :lyric, 0x06 => :marker, 0x07 => :cue_point
  }.freeze

  # Meta data shorter than these is malformed; longer, only the prefix is read.
  META_LENGTHS = {0x51 => 3, 0x58 => 4, 0x59 => 2}.freeze

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
      events.find { |event| event.is_a?(HeadMusic::MIDI::Text) && %i[sequence_name track_name].include?(event.kind) }&.text
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
      tracks.first&.events&.find { |event| event.is_a?(HeadMusic::MIDI::Text) && event.kind == :sequence_name }&.text
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
    raise parse_error("file is longer than #{MAX_BYTES} bytes", MAX_BYTES) if @bytes.bytesize > MAX_BYTES

    read_header
    tracks = read_tracks
    pair(Sequence.new(@format, @division, tracks), tracks.map { |track| track.events.last&.tick || 0 })
  end

  private

  def parse_error(message, offset)
    HeadMusic::MIDI::ParseError.new(message, offset: offset)
  end

  def unsupported(message, offset)
    HeadMusic::MIDI::UnsupportedFeatureError.new(message, offset: offset)
  end

  def read_header
    raise parse_error("no MThd header", 0) unless @bytes.byteslice(0, 4) == "MThd"

    _type, length, start = chunk_header(0)
    raise parse_error("MThd is shorter than 6 bytes", 4) if length < 6

    @format, @track_count, @division = @bytes.byteslice(start, 6).unpack("nnn")
    check_format
    check_division
    @max_tick = @division * 4 * MAX_WHOLE_NOTES
    @offset = start + length
  end

  def check_format
    raise parse_error("format #{@format} is not a Standard MIDI File format", 8) if @format > 2
    raise unsupported("format 2 holds independent sequences, not one piece", 8) if @format == 2
  end

  def check_division
    raise unsupported("an SMPTE time division has no beat", 12) if @division >= 0x8000
    raise parse_error("division of 0", 12) if @division.zero?
  end

  def chunk_header(at)
    raise parse_error("truncated chunk header", at) if at + 8 > @bytes.bytesize

    type, length = @bytes.byteslice(at, 8).unpack("a4N")
    raise parse_error("chunk #{type.inspect} overruns the file", at) if at + 8 + length > @bytes.bytesize

    [type, length, at + 8]
  end

  # Every complete chunk is read, even past the declared count, since some
  # writers undercount; whatever follows the declared tracks that is not a
  # complete chunk is ignored.
  def read_tracks
    tracks = []
    while @offset < @bytes.bytesize
      break if tracks.length >= @track_count && !complete_chunk?

      type, length, start = chunk_header(@offset)
      @offset = start + length
      tracks << read_track(start, @offset, tracks.length) if type == "MTrk"
    end
    raise parse_error("expected #{@track_count} tracks, found #{tracks.length}", @offset) if tracks.length < @track_count

    tracks
  end

  def complete_chunk?
    @offset + 8 <= @bytes.bytesize && @offset + 8 + @bytes.byteslice(@offset + 4, 4).unpack1("N") <= @bytes.bytesize
  end

  def read_track(start, limit, index)
    @limit = limit
    @position = start
    @tick = 0
    @running = nil
    events = []
    while @position < limit
      event = read_timed_event
      return track(events << event, true, index) if event.is_a?(HeadMusic::MIDI::EndOfTrack)

      events << event if event
    end
    track(events, false, index)
  end

  def track(events, terminated, index)
    events = sequence_named(events) if index.zero?
    Track.new(events, terminated)
  end

  # Format 1 writers that put notes in track 0 name a part there, not the piece.
  def sequence_named(events)
    return events unless @format.zero? || events.none?(HeadMusic::MIDI::NoteOn)

    events.map { |event| (event.is_a?(HeadMusic::MIDI::Text) && event.kind == :track_name) ? event.with(kind: :sequence_name) : event }
  end

  def read_timed_event
    at = @position
    @tick += read_vlq
    raise parse_error("event at tick #{@tick} is beyond #{MAX_WHOLE_NOTES} whole notes", at) if @tick > @max_tick

    @event_count += 1
    raise parse_error("more than #{MAX_EVENTS} events", at) if @event_count > MAX_EVENTS

    read_event
  end

  def read_byte
    raise parse_error("unexpected end of chunk", @position) if @position >= @limit

    byte = @bytes.getbyte(@position)
    @position += 1
    byte
  end

  def read_bytes(count)
    raise parse_error("unexpected end of chunk", @position) if @position + count > @limit

    data = @bytes.byteslice(@position, count)
    @position += count
    data
  end

  def read_vlq
    at = @position
    value = 0
    4.times do
      byte = read_byte
      value = (value << 7) | (byte & 0x7F)
      return value if byte < 0x80
    end
    raise parse_error("over-long variable-length quantity", at)
  end

  def read_event
    at = @position
    status = status_byte(at)
    case status
    when 0xFF then read_meta(at)
    when 0xF0, 0xF7 then read_sysex
    when 0x80..0xEF then read_channel_message(status)
    else raise parse_error(format("unknown status byte 0x%02X", status), at)
    end
  end

  def status_byte(at)
    raise parse_error("unexpected end of chunk", at) if at >= @limit

    status = @bytes.getbyte(at)
    return @running || raise(parse_error("data byte with no running status", at)) if status < 0x80

    @position += 1
    status
  end

  def read_meta(at)
    type = read_byte
    data = read_bytes(read_vlq)
    needed = META_LENGTHS.fetch(type, 0)
    raise parse_error(format("meta event 0x%02X needs %d bytes, not %d", type, needed, data.bytesize), at) if data.bytesize < needed

    meta_event(type, data, at)
  end

  def meta_event(type, data, at)
    case type
    when 0x2F then HeadMusic::MIDI::EndOfTrack.new(@tick)
    when 0x51 then tempo(data, at)
    when 0x58 then time_signature(data, at)
    when 0x59 then key_signature(data, at)
    else text_event(type, data)
    end
  end

  def tempo(data, at)
    microseconds = ("\x00".b + data.byteslice(0, 3)).unpack1("N")
    raise parse_error("tempo of 0", at) if microseconds.zero?

    HeadMusic::MIDI::Tempo.new(@tick, microseconds)
  end

  def time_signature(data, at)
    numerator, power, clocks = data.unpack("C3")
    raise parse_error("time signature numerator of 0", at) if numerator.zero?
    raise unsupported("time signature denominator 2^#{power} is above 64", at) if power > 6

    HeadMusic::MIDI::TimeSignature.new(@tick, numerator, 2**power, clocks)
  end

  def key_signature(data, at)
    fifths, mode = data.unpack("cC")
    raise parse_error("key signature of #{fifths} fifths", at) unless fifths.between?(-7, 7)
    raise parse_error("key signature mode #{mode}", at) unless mode <= 1

    HeadMusic::MIDI::KeySignature.new(@tick, fifths, mode == 1)
  end

  def text_event(type, data)
    kind = TEXT_KINDS[type]
    HeadMusic::MIDI::Text.new(@tick, kind, decode(data)) if kind
  end

  def decode(data)
    text = data.dup.force_encoding(Encoding::UTF_8)
    text = data.encode(Encoding::UTF_8, Encoding::Windows_1252, invalid: :replace, undef: :replace) unless text.valid_encoding?
    text.delete("\0")
  end

  def read_sysex
    @running = nil
    read_bytes(read_vlq)
    nil
  end

  def read_channel_message(status)
    @running = status
    channel = status & 0x0F
    data = Array.new([0xC0, 0xD0].include?(status & 0xF0) ? 1 : 2) { read_data_byte }
    case status & 0xF0
    when 0x80 then HeadMusic::MIDI::NoteOff.new(@tick, channel, *data)
    when 0x90 then note_on(channel, *data)
    when 0xC0 then HeadMusic::MIDI::ProgramChange.new(@tick, channel, data.first + 1)
    end
  end

  def note_on(channel, key, velocity)
    return HeadMusic::MIDI::NoteOff.new(@tick, channel, key, 0) if velocity.zero?

    HeadMusic::MIDI::NoteOn.new(@tick, channel, key, velocity)
  end

  def read_data_byte
    at = @position
    byte = read_byte
    raise parse_error("status byte where data was expected", at) if byte >= 0x80

    byte
  end

  # Pairs each note off with the earliest sounding note on of its channel and key
  # across every track, since a writer may release a note in another track. A
  # note never released ends at its own track's last tick.
  def pair(sequence, end_ticks)
    notes = Array.new(sequence.tracks.length) { [] }
    held = Hash.new { |hash, key| hash[key] = [] }
    sequence.indexed_events.each do |track_index, event|
      case event
      when HeadMusic::MIDI::NoteOn then held[[event.channel, event.key]] << [track_index, event]
      when HeadMusic::MIDI::NoteOff then release(held[[event.channel, event.key]].shift, event.tick, notes)
      end
    end
    held.each_value { |queue| queue.each { |sounding| release(sounding, end_ticks[sounding.first], notes) } }
    tracks = sequence.tracks.zip(notes).map { |track, track_notes| Track.new(track.events, track.terminated, self.class.sorted(track_notes)) }
    Sequence.new(sequence.format, sequence.division, tracks)
  end

  def release(sounding, tick, notes)
    return unless sounding

    track_index, on = sounding
    notes[track_index] << Note.new(on.channel, on.key, on.velocity, on.tick, tick, track_index)
  end
end
