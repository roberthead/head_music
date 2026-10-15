# Decodes a Standard MIDI File into the writer's event value objects, so specs
# assert on events and ticks rather than raw bytes. MIDI Import may promote it
# into the gem. It reads more than the writer writes: running status, a note
# on at velocity 0 as a note off, and unknown chunks, as other tools write them.
class HeadMusic::MIDI::Reader
  Sequence = Data.define(:format, :division, :tracks)

  Note = Data.define(:channel, :key, :velocity, :on, :off) do
    def duration
      off - on
    end
  end

  class Track
    attr_reader :events

    def initialize(events)
      @events = events
    end

    def of(kind)
      events.grep(kind)
    end

    # Each note on paired with the next note off of its channel and key.
    def notes
      held = Hash.new { |hash, key| hash[key] = [] }
      events.each_with_object([]) do |event, notes|
        case event
        when HeadMusic::MIDI::NoteOn
          held[[event.channel, event.key]] << event
        when HeadMusic::MIDI::NoteOff
          on = held[[event.channel, event.key]].shift
          notes << Note.new(on.channel, on.key, on.velocity, on.tick, event.tick) if on
        end
      end.sort_by { |note| [note.on, note.channel, note.key] }
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

  TEXT_KINDS = {
    0x01 => :text, 0x02 => :copyright, 0x03 => :track_name, 0x04 => :instrument_name,
    0x05 => :lyric, 0x06 => :marker, 0x07 => :cue_point
  }.freeze

  def initialize(bytes)
    @bytes = bytes.b
    @offset = 0
  end

  def read
    type, length, start = chunk_header
    raise parse_error("no MThd header", 0) unless type == "MThd" && length >= 6

    format, track_count, division = @bytes.byteslice(start, 6).unpack("nnn")
    @format = format
    @offset = start + length
    tracks = []
    while @offset < @bytes.bytesize
      type, length, start = chunk_header
      @offset = start + length
      tracks << read_track(start, start + length, tracks.length) if type == "MTrk"
    end
    raise parse_error("expected #{track_count} tracks, found #{tracks.length}", @offset) unless tracks.length == track_count

    Sequence.new(format, division, tracks)
  end

  private

  def parse_error(message, offset)
    HeadMusic::MIDI::ParseError.new(message, offset: offset)
  end

  def chunk_header
    at = @offset
    raise parse_error("truncated chunk header", at) if at + 8 > @bytes.bytesize

    type, length = @bytes.byteslice(at, 8).unpack("a4N")
    raise parse_error("chunk #{type.inspect} overruns the file", at) if at + 8 + length > @bytes.bytesize

    [type, length, at + 8]
  end

  def read_track(start, limit, index)
    @limit = limit
    @position = start
    @tick = 0
    @running = nil
    @track_index = index
    events = []
    until @position >= limit
      @tick += read_vlq
      event = read_event
      return Track.new(events << event) if event.is_a?(HeadMusic::MIDI::EndOfTrack)

      events << event if event
    end
    raise parse_error("missing end-of-track", limit)
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
    status = @bytes.getbyte(@position)
    if status && status >= 0x80
      @position += 1
    else
      raise parse_error("data byte with no running status", at) unless @running

      status = @running
    end
    case status
    when 0xFF then read_meta
    when 0xF0, 0xF7 then read_sysex
    when 0x80..0xEF then read_channel_message(status)
    else raise parse_error(format("unknown status byte 0x%02X", status), at)
    end
  end

  def read_meta
    @running = nil
    type = read_byte
    data = read_bytes(read_vlq)
    meta_event(type, data)
  end

  def meta_event(type, data)
    case type
    when 0x2F then HeadMusic::MIDI::EndOfTrack.new(@tick)
    when 0x51 then HeadMusic::MIDI::Tempo.new(@tick, ("\x00".b + data).unpack1("N"))
    when 0x58 then time_signature(data)
    when 0x59 then HeadMusic::MIDI::KeySignature.new(@tick, *data.unpack("cC").then { |fifths, minor| [fifths, minor == 1] })
    else text_event(type, data)
    end
  end

  def time_signature(data)
    numerator, power, clocks = data.unpack("C3")
    HeadMusic::MIDI::TimeSignature.new(@tick, numerator, 2**power, clocks)
  end

  def text_event(type, data)
    kind = TEXT_KINDS[type]
    return unless kind

    kind = :sequence_name if kind == :track_name && @track_index.zero? && @format == 1
    HeadMusic::MIDI::Text.new(@tick, kind, data.force_encoding(Encoding::UTF_8))
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
end
