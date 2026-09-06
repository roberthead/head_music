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
      def initialize(starting_meter: nil, starting_position: nil)
        starting_meter = HeadMusic::Rudiment::Meter.get(starting_meter || "4/4")
        starting_position ||= MusicalPosition.new
        # The opening meter is not removable: a timeline with no meter at all
        # has no bars, so there is always one in force.
        @map = EventMap.new(removable_first_event: false)
        @map.add(starting_position, MeterEvent.new(starting_position, starting_meter))
      end

      # @return [Array<MeterEvent>] all meter events in chronological order
      def events
        @map.values
      end

      def add_change(position, meter_or_identifier)
        meter = meter_or_identifier.is_a?(HeadMusic::Rudiment::Meter) ? meter_or_identifier : HeadMusic::Rudiment::Meter.get(meter_or_identifier)
        MeterEvent.new(position, meter).tap { |event| @map.add(position, event) }
      end

      def remove_change(position)
        @map.remove(position)
      end

      def clear_changes
        @map.clear
      end

      def meter_at(position)
        @map.at(position)&.meter || events.first.meter
      end

      # @return [MeterEvent, nil] the meter change starting exactly here
      def change_at(position)
        @map.change_at(position)&.value
      end

      def each_segment(from_position, to_position, &block)
        @map.each_segment(from_position, to_position) do |start_position, end_position, event|
          block.call(start_position, end_position, event&.meter || events.first.meter)
        end
      end
    end
  end
end
