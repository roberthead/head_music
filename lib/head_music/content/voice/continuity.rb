class HeadMusic::Content::Voice
  # Examines a voice's voice events for the first break in its coverage of time.
  # A voice is continuous when its first voice event starts a bar and every later
  # voice event begins where the one before it ends.
  class Continuity
    attr_reader :flow, :voice_events

    def initialize(flow, voice_events)
      @flow = flow
      @voice_events = voice_events
    end

    # Returns nil when the voice events are contiguous, or [expected_position,
    # found_voice_event] for the first gap.
    def first_gap
      return if voice_events.empty?

      leading_gap || interior_gap
    end

    private

    def leading_gap
      first = voice_events.first
      return if starts_its_bar?(first)

      [bar_start_position(first), first]
    end

    def interior_gap
      voice_events.each_cons(2) do |previous, current|
        expected_position = previous.next_position
        return [expected_position, current] unless current.position == expected_position
      end
      nil
    end

    def starts_its_bar?(voice_event)
      position = voice_event.position
      position.count == 1 && position.tick.zero?
    end

    def bar_start_position(voice_event)
      HeadMusic::Content::Position.new(flow, voice_event.position.bar_number, 1, 0)
    end
  end
end
