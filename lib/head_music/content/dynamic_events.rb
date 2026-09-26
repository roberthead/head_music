# A module for musical content
module HeadMusic::Content; end

# The dynamic events of a voice or a part, kept in position order. Unlike the
# meter and tempo maps, a second event at a position raises rather than
# replacing the first, because two dynamics at one instant are almost always
# a mistake.
class HeadMusic::Content::DynamicEvents
  include Enumerable

  delegate :each, :empty?, :length, to: :@events

  def initialize(flow)
    @flow = flow
    @events = []
  end

  def place(position, level)
    dynamic_event = HeadMusic::Content::DynamicEvent.new(@flow, position, level)
    index = @events.bsearch_index { |existing| existing.position >= dynamic_event.position } || @events.length
    if @events[index]&.position == dynamic_event.position
      raise ArgumentError, "a dynamic is already placed at #{dynamic_event.position}"
    end

    @events.insert(index, dynamic_event)
    dynamic_event
  end

  # The latest event at or before the position, or nil.
  def latest_at(position)
    index = @events.bsearch_index { |existing| existing.position > position } || @events.length
    @events[index - 1] if index.positive?
  end

  def to_a
    @events.dup
  end
end
