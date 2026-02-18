# frozen_string_literal: true

module HeadMusic
  module Time
    # Shared support for MeterMap and TempoMap event management
    module EventMapSupport
      private

      def sort_events!
        @events.sort_by! do |event|
          position = event.position
          [position.bar, position.beat, position.tick, position.subtick]
        end
      end

      def positions_equal?(first_position, second_position)
        position_tuple(first_position) == position_tuple(second_position)
      end

      def compare_positions(first_position, second_position)
        position_tuple(first_position) <=> position_tuple(second_position)
      end

      def position_tuple(position)
        [position.bar, position.beat, position.tick, position.subtick]
      end
    end
  end
end
