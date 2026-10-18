module HeadMusic::MIDI
  # Decodes a meta event's data as the event it states at a tick, or nil for
  # a type a flow cannot hold.
  class MetaReader
    # A sequence name and a track name share a type, read as the track name.
    TEXT_KINDS = Meta::TEXT_TYPES.invert.freeze

    # Data shorter than these is malformed; longer, only the prefix is read.
    LENGTHS = {0x51 => 3, 0x58 => 4, 0x59 => 2}.freeze

    # +offset+ is the event's byte offset, named by any error.
    def initialize(tick, offset)
      @tick = tick
      @offset = offset
    end

    def event(type, data)
      needed = LENGTHS.fetch(type, 0)
      raise parse_error(format("meta event 0x%02X needs %d bytes, not %d", type, needed, data.bytesize)) if data.bytesize < needed

      case type
      when 0x2F then EndOfTrack.new(@tick)
      when 0x51 then tempo(data)
      when 0x58 then time_signature(data)
      when 0x59 then key_signature(data)
      else text(type, data)
      end
    end

    private

    def parse_error(message)
      ParseError.new(message, offset: @offset)
    end

    def tempo(data)
      microseconds = ("\x00".b + data.byteslice(0, 3)).unpack1("N")
      raise parse_error("tempo of 0") if microseconds.zero?

      Tempo.new(@tick, microseconds)
    end

    def time_signature(data)
      numerator, power, clocks = data.unpack("C3")
      raise parse_error("time signature numerator of 0") if numerator.zero?
      raise UnsupportedFeatureError.new("time signature denominator 2^#{power} is above 64", offset: @offset) if power > 6

      TimeSignature.new(@tick, numerator, 2**power, clocks)
    end

    def key_signature(data)
      fifths, mode = data.unpack("cC")
      raise parse_error("key signature of #{fifths} fifths") unless fifths.between?(-7, 7)
      raise parse_error("key signature mode #{mode}") unless mode <= 1

      KeySignature.new(@tick, fifths, mode == 1)
    end

    def text(type, data)
      kind = TEXT_KINDS[type]
      Text.new(@tick, kind, decode(data)) if kind
    end

    def decode(data)
      text = data.dup.force_encoding(Encoding::UTF_8)
      text = data.encode(Encoding::UTF_8, Encoding::Windows_1252, invalid: :replace, undef: :replace) unless text.valid_encoding?
      text.delete("\0")
    end
  end
end
