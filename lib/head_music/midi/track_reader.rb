module HeadMusic::MIDI
  # Decodes one MTrk chunk's events: delta times, running status, a note on
  # at velocity 0 as a note off, and meta events. Sysex and the channel
  # messages a flow cannot hold are read past and skipped.
  class TrackReader
    attr_reader :event_count

    # +events_before+ is how many events earlier tracks held, since the
    # limit on events is the file's.
    def initialize(bytes, start, limit, division:, events_before: 0)
      @bytes = bytes
      @position = start
      @limit = limit
      @max_tick = division * 4 * Reader::MAX_WHOLE_NOTES
      @events_before = events_before
      @event_count = 0
      @tick = 0
      @running = nil
    end

    def track
      events = []
      while @position < @limit
        event = read_timed_event
        return Reader::Track.new(events << event, true) if event.is_a?(EndOfTrack)

        events << event if event
      end
      Reader::Track.new(events, false)
    end

    private

    def parse_error(message, offset)
      ParseError.new(message, offset: offset)
    end

    def read_timed_event
      at = @position
      @tick += read_vlq
      raise parse_error("event at tick #{@tick} is beyond #{Reader::MAX_WHOLE_NOTES} whole notes", at) if @tick > @max_tick

      @event_count += 1
      raise parse_error("more than #{Reader::MAX_EVENTS} events", at) if @events_before + @event_count > Reader::MAX_EVENTS

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
      when 0xFF then MetaReader.new(@tick, at).event(read_byte, read_bytes(read_vlq))
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
      when 0x80 then NoteOff.new(@tick, channel, *data)
      when 0x90 then note_on(channel, *data)
      when 0xC0 then ProgramChange.new(@tick, channel, data.first + 1)
      end
    end

    def note_on(channel, key, velocity)
      return NoteOff.new(@tick, channel, key, 0) if velocity.zero?

      NoteOn.new(@tick, channel, key, velocity)
    end

    def read_data_byte
      at = @position
      byte = read_byte
      raise parse_error("status byte where data was expected", at) if byte >= 0x80

      byte
    end
  end
end
