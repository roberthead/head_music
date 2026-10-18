module HeadMusic::MIDI
  # Walks sorted changes forward beside a sweep of ascending points, so a
  # whole sweep passes each change once.
  class ChangeCursor
    # The [point, value] pairs whose value differs from the one before.
    def self.changes(pairs)
      pairs.chunk_while { |one, other| one.last == other.last }.map(&:first)
    end

    # The block answers a change's point.
    def initialize(changes, &point)
      @changes = changes
      @point = point
      @index = 0
    end

    # The changes at or before +point+ not reached by an earlier call.
    def advance(point)
      from = @index
      @index += 1 while @index < @changes.length && @point.call(@changes[@index]) <= point
      @changes[from...@index]
    end

    # The latest change at or before +point+, or nil before the first.
    def at(point)
      advance(point)
      @changes[@index - 1] if @index.positive?
    end
  end
end
