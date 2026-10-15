# Encodes timed events as a format 1 Standard MIDI File, without running status.
module HeadMusic::MIDI::SMF
  MAX_VLQ = 0x0FFFFFFF
  MAX_DIVISION = 0x7FFF

  module_function

  def vlq(number)
    raise ArgumentError, "#{number.inspect} is not a variable-length quantity (0..#{MAX_VLQ})" unless number.is_a?(Integer) && number.between?(0, MAX_VLQ)

    bytes = [number & 0x7F]
    number >>= 7
    while number.positive?
      bytes.unshift((number & 0x7F) | 0x80)
      number >>= 7
    end
    bytes.pack("C*")
  end

  # +tracks+ is a list of event lists, each in any order.
  def file(division:, tracks:)
    raise ArgumentError, "#{division.inspect} is not a division (1..#{MAX_DIVISION})" unless division.is_a?(Integer) && division.between?(1, MAX_DIVISION)

    header = ["MThd".b, 6, 1, tracks.length, division].pack("a4Nnnn")
    tracks.each_with_object(header) { |events, bytes| bytes << chunk(track_body(events)) }
  end

  def chunk(body)
    ["MTrk".b, body.bytesize].pack("a4N") + body
  end

  # MRI's sort_by is not stable, so the insertion index breaks ties.
  def track_body(events)
    previous = 0
    sorted = events.each_with_index.sort_by { |event, index| [event.tick, event.rank, index] }.map(&:first)
    sorted.each_with_object(String.new(encoding: Encoding::BINARY)) do |event, body|
      body << vlq(event.tick - previous) << event.payload
      previous = event.tick
    end
  end
end
