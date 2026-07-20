# frozen_string_literal: true

module HeadMusic
  module Time
    # Converts between clock time (elapsed nanoseconds) and musical position
    # (bars:beats:ticks:subticks) using a tempo map and a meter map, walking the
    # timeline one tempo segment at a time so tempo and meter changes are
    # accounted for. Subticks are the shared integer unit both directions pass
    # through.
    class MusicalTimeConverter
      def initialize(tempo_map:, meter_map:, starting_musical_position:)
        @tempo_map = tempo_map
        @meter_map = meter_map
        @starting_musical_position = starting_musical_position
      end

      # @param clock_position [ClockPosition] the clock time to convert
      # @return [MusicalPosition] the corresponding musical position
      def clock_to_musical(clock_position)
        target_nanoseconds = clock_position.nanoseconds
        accumulated_nanoseconds = 0
        current_position = starting_musical_position

        # We need an end position far enough to contain our target clock time
        estimated_end = MusicalPosition.new(starting_musical_position.bar + 1000, 1, 0, 0)

        tempo_map.each_segment(starting_musical_position, estimated_end) do |start_pos, end_pos, tempo|
          meter = meter_map.meter_at(start_pos)
          segment_nanoseconds = nanoseconds_in_segment(start_pos, end_pos, tempo, meter)

          # If our target falls within this segment, calculate the exact position
          if accumulated_nanoseconds + segment_nanoseconds >= target_nanoseconds
            remaining_nanoseconds = target_nanoseconds - accumulated_nanoseconds
            total_subticks = musical_position_to_subticks(start_pos, meter) +
              nanoseconds_to_subticks(remaining_nanoseconds, tempo)
            return subticks_to_musical_position(total_subticks, meter)
          end

          accumulated_nanoseconds += segment_nanoseconds
          current_position = end_pos
        end

        # If we get here, return the last position (shouldn't normally happen)
        current_position
      end

      # @param musical_position [MusicalPosition] the musical position to convert
      # @return [ClockPosition] the corresponding clock time
      def musical_to_clock(musical_position)
        total_nanoseconds = 0

        # Iterate through each tempo segment from start to target position
        tempo_map.each_segment(starting_musical_position, musical_position) do |start_pos, end_pos, tempo|
          meter = meter_map.meter_at(start_pos)
          total_nanoseconds += nanoseconds_in_segment(start_pos, end_pos, tempo, meter)
        end

        ClockPosition.new(total_nanoseconds)
      end

      private

      attr_reader :tempo_map, :meter_map, :starting_musical_position

      # Convert a musical position to total subticks for calculation
      def musical_position_to_subticks(position, meter = nil)
        meter ||= meter_map.meter_at(position)
        subticks_per_count = meter.ticks_per_count * HeadMusic::Time::SUBTICKS_PER_TICK
        subticks_per_bar = meter.counts_per_bar * subticks_per_count

        (position.bar - 1) * subticks_per_bar +
          (position.beat - 1) * subticks_per_count +
          position.tick * HeadMusic::Time::SUBTICKS_PER_TICK +
          position.subtick
      end

      # Clock duration of a tempo segment, in nanoseconds
      def nanoseconds_in_segment(start_pos, end_pos, tempo, meter)
        segment_subticks = musical_position_to_subticks(end_pos, meter) -
          musical_position_to_subticks(start_pos, meter)
        segment_ticks = segment_subticks / HeadMusic::Time::SUBTICKS_PER_TICK.to_f
        (segment_ticks * tempo.tick_duration_in_nanoseconds).round
      end

      # Convert an elapsed nanosecond duration into subticks at the given tempo
      def nanoseconds_to_subticks(nanoseconds, tempo)
        ticks = nanoseconds / tempo.tick_duration_in_nanoseconds.to_f
        (ticks * HeadMusic::Time::SUBTICKS_PER_TICK).round
      end

      # Decompose total subticks into a normalized bar:beat:tick:subtick position
      def subticks_to_musical_position(total_subticks, meter)
        subticks_per_count = meter.ticks_per_count * HeadMusic::Time::SUBTICKS_PER_TICK
        subticks_per_bar = meter.counts_per_bar * subticks_per_count

        bars, remaining = total_subticks.divmod(subticks_per_bar)
        beats, remaining = remaining.divmod(subticks_per_count)
        ticks, subticks = remaining.divmod(HeadMusic::Time::SUBTICKS_PER_TICK)

        MusicalPosition.new(bars + 1, beats + 1, ticks, subticks).normalize!(meter)
      end
    end
  end
end
