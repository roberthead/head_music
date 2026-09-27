class HeadMusic::Content::Voice
  # Finds the dynamic level in force at a position in a voice: the latest of
  # the voice's own dynamic events, its part's, and any accent that leaves a
  # level behind it, as fp leaves p. At one position the accent wins, then the
  # voice's own event, then the part's. Nil where nothing has been written.
  class DynamicResolver
    attr_reader :voice, :dynamic_events

    delegate :flow, :part, :voice_events, to: :voice

    # @param dynamic_events [HeadMusic::Content::DynamicEvents] the voice's own
    def initialize(voice, dynamic_events)
      @voice = voice
      @dynamic_events = dynamic_events
    end

    def level_at(position)
      position = HeadMusic::Content::Position.new(flow, position) unless position.is_a?(HeadMusic::Content::Position)
      event = latest_event_at(position)
      accent_level_at(position, event&.position) || event&.level
    end

    private

    # The voice's own event outranks the part's at the same position.
    def latest_event_at(position)
      [part.dynamic_event_at(position), dynamic_events.latest_at(position)]
        .each_with_index
        .select(&:first)
        .max_by { |event, rank| [event.position, rank] }
        &.first
    end

    # The level left behind by the latest accent such as fp at or before the
    # position, when no dynamic event comes after it. Walks back only as far as
    # the floor, so a writer asking at every note stays linear.
    def accent_level_at(position, floor)
      index = voice_events.bsearch_index { |voice_event| voice_event.position > position } || voice_events.length
      (index - 1).downto(0) do |candidate_index|
        voice_event = voice_events[candidate_index]
        break if floor && voice_event.position < floor

        level = voice_event.note_dynamic&.level_after
        return level if level
      end
      nil
    end
  end
end
