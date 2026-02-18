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
      include EventMapSupport

      # @return [Array<TempoEvent>] all tempo events in chronological order
      attr_reader :events

      def initialize(starting_tempo: nil, starting_position: nil)
        starting_tempo ||= HeadMusic::Rudiment::Tempo.new("quarter", 120)
        starting_position ||= MusicalPosition.new
        @events = [TempoEvent.new(starting_position, starting_tempo.beat_value.to_s, starting_tempo.beats_per_minute)]
        @meter = nil
      end

      def add_change(position, beat_value_or_tempo, beats_per_minute = nil)
        remove_change(position)
        event = if beat_value_or_tempo.is_a?(HeadMusic::Rudiment::Tempo)
          TempoEvent.new(position, beat_value_or_tempo.beat_value.to_s, beat_value_or_tempo.beats_per_minute).tap do |tempo_event|
            tempo_event.tempo = beat_value_or_tempo
          end
        else
          TempoEvent.new(position, beat_value_or_tempo, beats_per_minute)
        end
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

      def tempo_at(position)
        normalized_pos = normalize_position(position)
        active_event = @events.reverse.find do |event|
          normalize_position(event.position) <= normalized_pos
        end
        active_event&.tempo || @events.first.tempo
      end

      def each_segment(from_position, to_position)
        from_pos = normalize_position(from_position)
        to_pos = normalize_position(to_position)

        relevant_events = @events.select do |event|
          normalize_position(event.position) < to_pos
        end

        current_pos = from_pos
        current_tempo = tempo_at(from_pos)

        relevant_events.each do |event|
          normalized_event_pos = normalize_position(event.position)
          next if normalized_event_pos <= from_pos

          yield current_pos, normalized_event_pos, current_tempo
          current_pos = normalized_event_pos
          current_tempo = event.tempo
        end

        yield current_pos, to_pos, current_tempo
      end

      # @api private
      attr_writer :meter

      private

      def normalize_position(position)
        return position unless @meter

        position.dup.tap { |pos| pos.normalize!(@meter) }
      end
    end
  end
end
