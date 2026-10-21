class HeadMusic::Content::Flow
  # Timeline items that may begin in the middle of a bar -- tempo ramps,
  # "a tempo" points, or fermatas -- kept in order of their starts. Each runs
  # over the half-open span from its start to its end, and none may overlap
  # another; a point, which ends where it begins, overlaps another at the same
  # position. Positions compare by their coordinates, as the step changes'
  # downbeats do.
  class TimelineSpans
    include Enumerable

    delegate :each, :empty?, :length, to: :@items

    attr_reader :noun

    def initialize(noun)
      @noun = noun
      @items = []
    end

    def add(item)
      index = index_after(item.from)
      neighbors = [(@items[index - 1] if index.positive?), @items[index]].compact
      overlapped = neighbors.find { |other| overlap?(other, item) }
      raise ArgumentError, "the #{describe(item)} overlaps the #{describe(overlapped)}" if overlapped

      @items.insert(index, item)
      item
    end

    # @return [Object, nil] the removed item that began at a position
    def remove(from)
      index = @items.index { |item| item.from.to_a == from.to_a }
      @items.delete_at(index) if index
    end

    # @return [Object, nil] the item that has begun by a position and not yet ended
    def covering(position)
      item = latest_at_or_before(position)
      item if item && (position.to_a <=> item.to.to_a).negative?
    end

    # @return [Object, nil] the item that began latest at or before a position
    def latest_at_or_before(position)
      index = index_after(position)
      @items[index - 1] if index.positive?
    end

    def to_a
      @items.dup
    end

    def describe(item)
      (item.from.to_a == item.to.to_a) ? "#{noun} at #{item.from}" : "#{noun} from #{item.from} to #{item.to}"
    end

    private

    def index_after(position)
      tuple = position.to_a
      @items.bsearch_index { |item| (item.from.to_a <=> tuple).positive? } || @items.length
    end

    def overlap?(one, other)
      one.from.to_a == other.from.to_a ||
        ((one.from.to_a <=> other.to.to_a).negative? && (other.from.to_a <=> one.to.to_a).negative?)
    end
  end
end
