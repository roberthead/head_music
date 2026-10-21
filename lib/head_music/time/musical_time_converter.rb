# frozen_string_literal: true

module HeadMusic
  module Time
    # Converts between clock time (elapsed nanoseconds) and musical position
    # (bars:beats:ticks:subticks) using a tempo map and a meter map. Both
    # directions pass through subticks measured along a MeterScale, so a tempo
    # segment that crosses a meter change counts each bar in its own meter.
    class MusicalTimeConverter
      def initialize(tempo_map:, meter_map:, starting_musical_position:)
        @tempo_map = tempo_map
        @meter_scale = MeterScale.new(meter_map)
        @starting_musical_position = starting_musical_position
      end

      # @param clock_position [ClockPosition] the clock time to convert
      # @return [MusicalPosition] the corresponding musical position
      def clock_to_musical(clock_position)
        remaining = Rational(clock_position.nanoseconds)
        each_piece do |start, finish, tempo|
          rate = nanoseconds_per_subtick(tempo)
          if finish.nil? || (finish - start) * rate >= remaining
            return meter_scale.position_at(start + (remaining / rate).round)
          end
          remaining -= (finish - start) * rate
        end
      end

      # @param musical_position [MusicalPosition] the musical position to convert
      # @return [ClockPosition] the corresponding clock time
      def musical_to_clock(musical_position)
        target = meter_scale.subticks_at(musical_position)
        total = Rational(0)
        each_piece do |start, finish, tempo|
          stop = finish.nil? ? target : [finish, target].min
          total += (stop - start) * nanoseconds_per_subtick(tempo) if stop > start
          break if finish.nil? || finish >= target
        end
        ClockPosition.new(total.round)
      end

      private

      attr_reader :tempo_map, :meter_scale, :starting_musical_position

      # Yields [start, finish, tempo] in subticks from the starting position
      # onward; the last piece has no finish.
      def each_piece
        start = meter_scale.subticks_at(starting_musical_position)
        tempo = tempo_map.tempo_at(starting_musical_position)
        tempo_map.events.each do |event|
          boundary = meter_scale.subticks_at(event.position)
          next if boundary <= start

          yield start, boundary, tempo
          start = boundary
          tempo = event.tempo
        end
        yield start, nil, tempo
      end

      def nanoseconds_per_subtick(tempo)
        Rational(HeadMusic::Rudiment::Tempo::NANOSECONDS_PER_MINUTE) /
          (tempo.beats_per_minute.to_r * tempo.ticks_per_beat * HeadMusic::Time::SUBTICKS_PER_TICK)
      end
    end
  end
end
