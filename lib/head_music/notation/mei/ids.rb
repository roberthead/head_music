module HeadMusic::Notation::MEI
  # The xml:ids of one mdiv, built only from integers and positions so that
  # the same flow always gets the same ids. Events are keyed by part, voice in
  # part, and onset, as m1-p1v2-b3c2t240; every other element by kind and key,
  # as m1-measure-b3.
  class Ids
    PATTERN = /\A[a-z][a-z0-9-]*\z/

    attr_reader :mdiv_number

    def initialize(mdiv_number)
      @mdiv_number = mdiv_number
    end

    def mdiv
      "m#{mdiv_number}"
    end

    def bar_key(bar_number)
      bar_number.negative? ? "bm#{-bar_number}" : "b#{bar_number}"
    end

    def position_key(position)
      tick = position.tick.zero? ? "" : "t#{position.tick}"
      subtick = position.subtick.zero? ? "" : "s#{position.subtick}"
      "#{bar_key(position.bar_number)}c#{position.count}#{tick}#{subtick}"
    end

    def owner_key(part_number, voice_number = nil)
      voice_number ? "p#{part_number}v#{voice_number}" : "p#{part_number}"
    end

    def staff_key(bar_number, staff_number)
      "#{bar_key(bar_number)}s#{staff_number}"
    end

    def event(part_number, voice_number, position)
      "#{mdiv}-#{owner_key(part_number, voice_number)}-#{position_key(position)}"
    end

    # The first link of a tied chain is the event itself.
    def link(event_id, index)
      index.zero? ? event_id : "#{event_id}-k#{index}"
    end

    def chord_member(chord_id, index)
      "#{chord_id}-h#{index + 1}"
    end

    def grace(event_id, index)
      "#{event_id}-g#{index + 1}"
    end

    def container(kind, key = nil)
      id = [mdiv, kind, key].compact.join("-")
      raise ArgumentError, "#{id.inspect} is not a valid id" unless id.match?(PATTERN)

      id
    end

    def child(parent_id, kind, number = nil)
      "#{parent_id}-#{kind}#{number}"
    end
  end
end
