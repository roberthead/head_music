# Encodes timed events as a format 1 Standard MIDI File, without running status.
module HeadMusic::MIDI::SMF
  MAX_VLQ = 0x0FFFFFFF
  MAX_DIVISION = 0x7FFF

  module_function

  def vlq(number)
    check(number, 0..MAX_VLQ, "a variable-length quantity")

    *leading, last = number.digits(128).reverse
    [*leading.map { |digit| digit | 0x80 }, last].pack("C*")
  end

  # +tracks+ is a list of event lists, each in any order.
  def file(division:, tracks:)
    check(division, 1..MAX_DIVISION, "a division")

    header = ["MThd".b, 6, 1, tracks.length, division].pack("a4Nnnn")
    tracks.each_with_object(header) { |events, bytes| bytes << chunk(track_body(events)) }
  end

  def check(number, range, name)
    raise ArgumentError, "#{number.inspect} is not #{name} (#{range})" unless number.is_a?(Integer) && range.cover?(number)
  end
  private_class_method :check

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
