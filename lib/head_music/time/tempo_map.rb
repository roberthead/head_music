# frozen_string_literal: true

module HeadMusic
  module Time
    # Manages tempo changes along a musical timeline
    #
    # A TempoMap maintains a sorted list of tempo changes at specific musical
    # positions, allowing you to determine which tempo is active at any point
    # and iterate through tempo segments for time calculations.
    #
    # This is essential for converting between clock time and musical position
    # when the tempo changes during a composition.
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
      # @return [Array<TempoEvent>] all tempo events in chronological order
      attr_reader :events

      # Create a new tempo map
      #
      # @param starting_tempo [HeadMusic::Rudiment::Tempo] initial tempo (default: quarter = 120)
      # @param starting_position [MusicalPosition] where the initial tempo begins (default: 1:1:0:0)
      def initialize(starting_tempo: nil, starting_position: nil)
        starting_tempo ||= HeadMusic::Rudiment::Tempo.new("quarter", 120)
        starting_position ||= MusicalPosition.new
        @events = [TempoEvent.new(starting_position, starting_tempo.beat_value.to_s, starting_tempo.beats_per_minute)]
        @meter = nil # Will be set when used with a MeterMap
      end

      # Add a tempo change at the specified position
      #
      # If a tempo change already exists at this position, it will be replaced.
      # Events are automatically maintained in sorted order.
      #
      # @param position [MusicalPosition] where the tempo change occurs
      # @param beat_value_or_tempo [String, HeadMusic::Rudiment::Tempo] either a beat value like "quarter" or a Tempo object
      # @param beats_per_minute [Numeric, nil] BPM (required if beat_value_or_tempo is a string)
      # @return [TempoEvent] the created event
      def add_change(position, beat_value_or_tempo, beats_per_minute = nil)
        # Remove any existing event at this position (except the first)
        remove_change(position)

        # Create the new event
        event = if beat_value_or_tempo.is_a?(HeadMusic::Rudiment::Tempo)
          TempoEvent.new(position, beat_value_or_tempo.beat_value.to_s, beat_value_or_tempo.beats_per_minute).tap do |e|
            e.tempo = beat_value_or_tempo
          end
        else
          TempoEvent.new(position, beat_value_or_tempo, beats_per_minute)
        end

        @events << event
        sort_events!
        event
      end

      # Remove a tempo change at the specified position
      #
      # The starting tempo (first event) cannot be removed.
      #
      # @param position [MusicalPosition] the position of the event to remove
      # @return [void]
      def remove_change(position)
        @events.reject! do |event|
          event != @events.first && positions_equal?(event.position, position)
        end
      end

      # Remove all tempo changes except the starting tempo
      #
      # @return [void]
      def clear_changes
        @events = [@events.first]
      end

      # Find the tempo active at a given position
      #
      # Returns the tempo from the most recent tempo event at or before
      # the specified position.
      #
      # @param position [MusicalPosition] the position to query
      # @return [HeadMusic::Rudiment::Tempo] the active tempo
      def tempo_at(position)
        # Normalize positions for comparison if we have a meter
        normalized_pos = @meter ? position.dup.tap { |p| p.normalize!(@meter) } : position

        # Find the last event at or before this position
        active_event = @events.reverse.find do |event|
          normalized_event_pos = @meter ? event.position.dup.tap { |p| p.normalize!(@meter) } : event.position
          normalized_event_pos <= normalized_pos
        end

        active_event&.tempo || @events.first.tempo
      end

      # Iterate through tempo segments between two positions
      #
      # Yields each segment with its start position, end position, and tempo.
      # Segments are created wherever a tempo change occurs within the range.
      #
      # @param from_position [MusicalPosition] start of the range
      # @param to_position [MusicalPosition] end of the range
      # @yield [start_position, end_position, tempo] for each segment
      # @yieldparam start_position [MusicalPosition] segment start
      # @yieldparam end_position [MusicalPosition] segment end
      # @yieldparam tempo [HeadMusic::Rudiment::Tempo] active tempo
      # @return [void]
      def each_segment(from_position, to_position)
        # Normalize positions if we have a meter
        from_pos = @meter ? from_position.dup.tap { |p| p.normalize!(@meter) } : from_position
        to_pos = @meter ? to_position.dup.tap { |p| p.normalize!(@meter) } : to_position

        # Find events that affect this range
        relevant_events = @events.select do |event|
          normalized_event_pos = @meter ? event.position.dup.tap { |p| p.normalize!(@meter) } : event.position
          normalized_event_pos < to_pos
        end

        # Start with the tempo active at from_position
        current_pos = from_pos
        current_tempo = tempo_at(from_pos)

        # Iterate through relevant events
        relevant_events.each do |event|
          normalized_event_pos = @meter ? event.position.dup.tap { |p| p.normalize!(@meter) } : event.position

          # Skip events before our starting position
          next if normalized_event_pos <= from_pos

          # Yield the segment up to this event
          yield current_pos, normalized_event_pos, current_tempo

          # Move to next segment
          current_pos = normalized_event_pos
          current_tempo = event.tempo
        end

        # Yield the final segment to the end position
        yield current_pos, to_pos, current_tempo
      end

      # Set the meter for position normalization
      #
      # @param meter [HeadMusic::Rudiment::Meter] the meter to use
      # @return [void]
      # @api private
      attr_writer :meter

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
    end
  end
end
