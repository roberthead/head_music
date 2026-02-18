# frozen_string_literal: true

module HeadMusic
  module Time
    # Manages meter (time signature) changes along a musical timeline
    #
    # A MeterMap maintains a sorted list of meter changes at specific musical
    # positions, allowing you to determine which meter is active at any point
    # and iterate through meter segments for musical position calculations.
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
      include EventMapSupport

      # @return [Array<MeterEvent>] all meter events in chronological order
      attr_reader :events

      def initialize(starting_meter: nil, starting_position: nil)
        starting_meter = HeadMusic::Rudiment::Meter.get(starting_meter || "4/4")
        starting_position ||= MusicalPosition.new
        @events = [MeterEvent.new(starting_position, starting_meter)]
      end

      def add_change(position, meter_or_identifier)
        remove_change(position)
        meter = meter_or_identifier.is_a?(HeadMusic::Rudiment::Meter) ? meter_or_identifier : HeadMusic::Rudiment::Meter.get(meter_or_identifier)
        event = MeterEvent.new(position, meter)
        @events << event
        sort_events!
        event
      end

      def remove_change(position)
        @events.reject! do |event|
          event != @events.first && positions_equal?(event.position, position)
        end
      end

      def clear_changes
        @events = [@events.first]
      end

      def meter_at(position)
        active_event = @events.reverse.find do |event|
          compare_positions(event.position, position) <= 0
        end
        active_event&.meter || @events.first.meter
      end

      def each_segment(from_position, to_position)
        relevant_events = @events.select do |event|
          compare_positions(event.position, to_position) < 0
        end

        current_pos = from_position
        current_meter = meter_at(from_position)

        relevant_events.each do |event|
          next if compare_positions(event.position, from_position) <= 0

          yield current_pos, event.position, current_meter
          current_pos = event.position
          current_meter = event.meter
        end

        yield current_pos, to_position, current_meter
      end
    end
  end
end
