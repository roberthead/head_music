# frozen_string_literal: true

module HeadMusic
  module Time
    # The changes of one value along a musical timeline, such as the meter or
    # the tempo, kept by position over an opening event that is never
    # removed, since a timeline always has one value in force. Subclasses
    # answer #value_of, the value an event carries.
    class ChangeMap
      def initialize(opening_event)
        @map = EventMap.new(removable_first_event: false)
        @map.add(opening_event.position, opening_event)
      end

      # @return [Array] all events in chronological order
      def events
        @map.values
      end

      def remove_change(position)
        @map.remove(position)
      end

      def clear_changes
        @map.clear
      end

      # @return [Object, nil] the change starting exactly here
      def change_at(position)
        @map.change_at(position)&.value
      end

      def each_segment(from_position, to_position, &block)
        @map.each_segment(from_position, to_position) do |start_position, end_position, event|
          block.call(start_position, end_position, value_of(event || events.first))
        end
      end

      private

      def value_at(position)
        value_of(@map.at(position) || events.first)
      end
    end
  end
end
