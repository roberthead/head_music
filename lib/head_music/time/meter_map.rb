# frozen_string_literal: true

module HeadMusic
  module Time
    # Manages meter (time signature) changes along a musical timeline
    #
    # A MeterMap maintains a sorted list of meter changes at specific musical
    # positions, allowing you to determine which meter is active at any point
    # and iterate through meter segments for musical position calculations.
    #
    # This is essential for normalizing musical positions when the meter changes
    # during a composition.
    #
    # @example Basic usage
    #   meter_map = HeadMusic::Time::MeterMap.new
    #   meter_map.add_change(MusicalPosition.new(5, 1, 0, 0), "3/4")
    #   meter_map.add_change(MusicalPosition.new(9, 1, 0, 0), "6/8")
    #
    #   meter = meter_map.meter_at(MusicalPosition.new(7, 1, 0, 0))
    #   meter.to_s # => "3/4"
    #
    # @example Iterating through segments
    #   from = MusicalPosition.new(1, 1, 0, 0)
    #   to = MusicalPosition.new(10, 1, 0, 0)
    #   meter_map.each_segment(from, to) do |start_pos, end_pos, meter|
    #     # Process each meter segment
    #   end
    class MeterMap
      # @return [Array<MeterEvent>] all meter events in chronological order
      attr_reader :events

      # Create a new meter map
      #
      # @param starting_meter [HeadMusic::Rudiment::Meter, String] initial meter (default: 4/4)
      # @param starting_position [MusicalPosition] where the initial meter begins (default: 1:1:0:0)
      def initialize(starting_meter: nil, starting_position: nil)
        starting_meter = HeadMusic::Rudiment::Meter.get(starting_meter || "4/4")
        starting_position ||= MusicalPosition.new
        @events = [MeterEvent.new(starting_position, starting_meter)]
      end

      # Add a meter change at the specified position
      #
      # If a meter change already exists at this position, it will be replaced.
      # Events are automatically maintained in sorted order.
      #
      # @param position [MusicalPosition] where the meter change occurs
      # @param meter_or_identifier [String, HeadMusic::Rudiment::Meter] either a meter string like "3/4" or a Meter object
      # @return [MeterEvent] the created event
      def add_change(position, meter_or_identifier)
        # Remove any existing event at this position (except the first)
        remove_change(position)

        # Create the new event
        meter = meter_or_identifier.is_a?(HeadMusic::Rudiment::Meter) ? meter_or_identifier : HeadMusic::Rudiment::Meter.get(meter_or_identifier)
        event = MeterEvent.new(position, meter)

        @events << event
        sort_events!
        event
      end

      # Remove a meter change at the specified position
      #
      # The starting meter (first event) cannot be removed.
      #
      # @param position [MusicalPosition] the position of the event to remove
      # @return [void]
      def remove_change(position)
        @events.reject! do |event|
          event != @events.first && positions_equal?(event.position, position)
        end
      end

      # Remove all meter changes except the starting meter
      #
      # @return [void]
      def clear_changes
        @events = [@events.first]
      end

      # Find the meter active at a given position
      #
      # Returns the meter from the most recent meter event at or before
      # the specified position.
      #
      # @param position [MusicalPosition] the position to query
      # @return [HeadMusic::Rudiment::Meter] the active meter
      def meter_at(position)
        # Find the last event at or before this position
        # We need to compare positions carefully since they might not be normalized
        active_event = @events.reverse.find do |event|
          compare_positions(event.position, position) <= 0
        end

        active_event&.meter || @events.first.meter
      end

      # Iterate through meter segments between two positions
      #
      # Yields each segment with its start position, end position, and meter.
      # Segments are created wherever a meter change occurs within the range.
      #
      # @param from_position [MusicalPosition] start of the range
      # @param to_position [MusicalPosition] end of the range
      # @yield [start_position, end_position, meter] for each segment
      # @yieldparam start_position [MusicalPosition] segment start
      # @yieldparam end_position [MusicalPosition] segment end
      # @yieldparam meter [HeadMusic::Rudiment::Meter] active meter
      # @return [void]
      def each_segment(from_position, to_position)
        # Find events that affect this range
        relevant_events = @events.select do |event|
          compare_positions(event.position, to_position) < 0
        end

        # Start with the meter active at from_position
        current_pos = from_position
        current_meter = meter_at(from_position)

        # Iterate through relevant events
        relevant_events.each do |event|
          # Skip events before our starting position
          next if compare_positions(event.position, from_position) <= 0

          # Yield the segment up to this event
          yield current_pos, event.position, current_meter

          # Move to next segment
          current_pos = event.position
          current_meter = event.meter
        end

        # Yield the final segment to the end position
        yield current_pos, to_position, current_meter
      end

      private

      # Sort events by position
      #
      # @return [void]
      def sort_events!
        @events.sort_by! do |event|
          pos = event.position
          [pos.bar, pos.beat, pos.tick, pos.subtick]
        end
      end

      # Check if two positions are equal
      #
      # @param pos1 [MusicalPosition] first position
      # @param pos2 [MusicalPosition] second position
      # @return [Boolean] true if positions are equal
      def positions_equal?(pos1, pos2)
        pos1.bar == pos2.bar &&
          pos1.beat == pos2.beat &&
          pos1.tick == pos2.tick &&
          pos1.subtick == pos2.subtick
      end

      # Compare two positions
      #
      # @param pos1 [MusicalPosition] first position
      # @param pos2 [MusicalPosition] second position
      # @return [Integer] -1, 0, or 1
      def compare_positions(pos1, pos2)
        [pos1.bar, pos1.beat, pos1.tick, pos1.subtick] <=>
          [pos2.bar, pos2.beat, pos2.tick, pos2.subtick]
      end
    end
  end
end
