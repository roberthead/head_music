class HeadMusic::Content::Voice
  # Examines a voice's placements for the first break in its coverage of time.
  # A voice is continuous when its first placement starts a bar and every later
  # placement begins where the one before it ends.
  class Continuity
    attr_reader :flow, :placements

    def initialize(flow, placements)
      @flow = flow
      @placements = placements
    end

    # Returns nil when the placements are contiguous, or [expected_position,
    # found_placement] for the first gap.
    def first_gap
      return if placements.empty?

      leading_gap || interior_gap
    end

    private

    def leading_gap
      first = placements.first
      return if starts_its_bar?(first)

      [bar_start_position(first), first]
    end

    def interior_gap
      placements.each_cons(2) do |previous, current|
        expected_position = previous.next_position
        return [expected_position, current] unless current.position == expected_position
      end
      nil
    end

    def starts_its_bar?(placement)
      position = placement.position
      position.count == 1 && position.tick.zero?
    end

    def bar_start_position(placement)
      HeadMusic::Content::Position.new(flow, placement.position.bar_number, 1, 0)
    end
  end
end
