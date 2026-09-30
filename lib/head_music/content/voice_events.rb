# A module for musical content
module HeadMusic::Content; end

# The voice events of a voice, kept in position order with at most one at a
# position. Every lookup is a binary search over that order, which keeps
# placing a long voice linear in its length rather than quadratic.
class HeadMusic::Content::VoiceEvents
  include Enumerable

  delegate :each, :empty?, :length, to: :@events

  def initialize
    @events = []
  end

  # A position holds one event, so the one already there decides what placing
  # another on it makes. Answers the event that holds the position afterward.
  def place(voice_event)
    index = index_from(voice_event.position)
    existing = @events[index]
    return @events[index] = existing.merge(voice_event) if existing&.position == voice_event.position

    @events.insert(index, voice_event)
    voice_event
  end

  def at(position)
    voice_event = starting_from(position)
    voice_event if voice_event&.position == position
  end

  # The first voice event at or after a position.
  def starting_from(position)
    @events[index_from(position)]
  end

  # The note or rest that holds a position, whether it starts there or is
  # still sounding.
  def sounding_at(position)
    @events.bsearch { |voice_event| voice_event.next_position > position }
  end

  # The events themselves rather than a copy, since a voice's events are read
  # far more often than they are placed, and nothing outside places them.
  def to_a
    @events
  end

  private

  def index_from(position)
    @events.bsearch_index { |voice_event| voice_event.position >= position } || @events.length
  end
end
