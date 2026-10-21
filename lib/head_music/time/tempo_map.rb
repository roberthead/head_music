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
    class TempoMap < ChangeMap
      def initialize(starting_tempo: nil, starting_position: nil)
        starting_tempo ||= HeadMusic::Rudiment::Tempo.new("quarter", 120)
        starting_position ||= MusicalPosition.new
        # Converting a position to clock time needs a tempo from the beginning.
        super(TempoEvent.new(starting_position, starting_tempo))
      end

      def add_change(position, beat_value_or_tempo, beats_per_minute = nil)
        event = TempoEvent.new(position, beat_value_or_tempo, beats_per_minute)
        @map.add(position, event)
        event
      end

      def tempo_at(position)
        value_at(position)
      end

      private

      def value_of(event)
        event.tempo
      end
    end
  end
end
