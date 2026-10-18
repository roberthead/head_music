module HeadMusic::MIDI
  # The chunks of a Standard MIDI File of format 0 or 1: its MThd header,
  # and the byte range of each MTrk chunk, skipping unknown chunks.
  class ChunkReader
    attr_reader :format, :track_count, :division

    def initialize(bytes)
      @bytes = bytes
      read_header
    end

    # Yields each MTrk chunk's start and limit offsets, reading the chunks
    # only as the caller reads each. Every complete chunk is read, even past
    # the declared count, since some writers undercount; whatever follows
    # the declared tracks that is not a complete chunk is ignored.
    def each_track
      found = 0
      while @offset < @bytes.bytesize
        break if found >= track_count && !complete_chunk?

        type, length, start = chunk_header(@offset)
        @offset = start + length
        next unless type == "MTrk"

        yield start, @offset
        found += 1
      end
      raise parse_error("expected #{track_count} tracks, found #{found}", @offset) if found < track_count
    end

    private

    def parse_error(message, offset)
      ParseError.new(message, offset: offset)
    end

    def read_header
      raise parse_error("no MThd header", 0) unless @bytes.byteslice(0, 4) == "MThd"

      _type, length, start = chunk_header(0)
      raise parse_error("MThd is shorter than 6 bytes", 4) if length < 6

      @format, @track_count, @division = @bytes.byteslice(start, 6).unpack("nnn")
      check_format
      check_division
      @offset = start + length
    end

    def check_format
      raise parse_error("format #{format} is not a Standard MIDI File format", 8) if format > 2
      raise UnsupportedFeatureError.new("format 2 holds independent sequences, not one piece", offset: 8) if format == 2
    end

    def check_division
      raise UnsupportedFeatureError.new("an SMPTE time division has no beat", offset: 12) if division >= 0x8000
      raise parse_error("division of 0", 12) if division.zero?
    end

    def chunk_header(at)
      raise parse_error("truncated chunk header", at) if at + 8 > @bytes.bytesize

      type, length = @bytes.byteslice(at, 8).unpack("a4N")
      raise parse_error("chunk #{type.inspect} overruns the file", at) if at + 8 + length > @bytes.bytesize

      [type, length, at + 8]
    end

    def complete_chunk?
      @offset + 8 <= @bytes.bytesize && @offset + 8 + @bytes.byteslice(@offset + 4, 4).unpack1("N") <= @bytes.bytesize
    end
  end
end
