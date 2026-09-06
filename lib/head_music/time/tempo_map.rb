# frozen_string_literal: true

module HeadMusic
  module Time
    # Manages tempo changes along a musical timeline
    #
    # A TempoMap maintains a sorted list of tempo changes at specific musical
    # positions, allowing you to determine which tempo is active at any point
    # and iterate through tempo segments for time calculations.
    #
    # @example Basic usage
    #   tempo_map = HeadMusic::Time::TempoMap.new
    #   tempo_map.add_change(MusicalPosition.new(5, 1, 0, 0), "quarter", 96)
    #   tempo_map.add_change(MusicalPosition.new(9, 1, 0, 0), "quarter", 140)
    #
    #   tempo = tempo_map.tempo_at(MusicalPosition.new(7, 1, 0, 0))
    #   tempo.beats_per_minute # => 96.0
    #
    # @example Iterating through segments
    #   from = MusicalPosition.new(1, 1, 0, 0)
    #   to = MusicalPosition.new(10, 1, 0, 0)
    #   tempo_map.each_segment(from, to) do |start_pos, end_pos, tempo|
    #     # Calculate clock time for this segment
    #   end
    class TempoMap
      def initialize(starting_tempo: nil, starting_position: nil)
        starting_tempo ||= HeadMusic::Rudiment::Tempo.new("quarter", 120)
        starting_position ||= MusicalPosition.new
        # The opening tempo is not removable: converting a position to clock
        # time needs a tempo in force from the beginning.
        @map = EventMap.new(removable_first_event: false)
        @map.add(starting_position, TempoEvent.new(starting_position, starting_tempo.beat_value.to_s, starting_tempo.beats_per_minute))
      end

      # @return [Array<TempoEvent>] all tempo events in chronological order
      def events
        @map.values
      end

      def add_change(position, beat_value_or_tempo, beats_per_minute = nil)
        event = if beat_value_or_tempo.is_a?(HeadMusic::Rudiment::Tempo)
          TempoEvent.new(position, beat_value_or_tempo.beat_value.to_s, beat_value_or_tempo.beats_per_minute).tap do |tempo_event|
            tempo_event.tempo = beat_value_or_tempo
          end
        else
          TempoEvent.new(position, beat_value_or_tempo, beats_per_minute)
        end
        @map.add(position, event)
        event
      end

      def remove_change(position)
        @map.remove(position)
      end

      def clear_changes
        @map.clear
      end

      def tempo_at(position)
        @map.at(position)&.tempo || events.first.tempo
      end

      # @return [TempoEvent, nil] the tempo change starting exactly here
      def change_at(position)
        @map.change_at(position)&.value
      end

      def each_segment(from_position, to_position, &block)
        @map.each_segment(from_position, to_position) do |start_position, end_position, event|
          block.call(start_position, end_position, event&.tempo || events.first.tempo)
        end
      end
    end
  end
end
