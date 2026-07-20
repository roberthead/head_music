# frozen_string_literal: true

module HeadMusic
  module Time
    # Representation of a conductor track for musical material
    #
    # The Conductor class synchronizes three different time representations:
    # - Clock time: elapsed nanoseconds (source of truth)
    # - Musical position: bars:beats:ticks:subticks notation
    # - SMPTE timecode: hours:minutes:seconds:frames
    #
    # Each moment in a track corresponds to all three positions simultaneously.
    # The conductor handles conversions between these representations based on
    # the current tempo, meter, and framerate.
    #
    # @example Basic usage
    #   conductor = HeadMusic::Time::Conductor.new
    #   clock_pos = HeadMusic::Time::ClockPosition.new(1_000_000_000) # 1 second
    #   musical_pos = conductor.clock_to_musical(clock_pos)
    #   smpte = conductor.clock_to_smpte(clock_pos)
    #
    # @example With custom tempo and meter
    #   conductor = HeadMusic::Time::Conductor.new(
    #     starting_tempo: HeadMusic::Rudiment::Tempo.new("quarter", 96),
    #     starting_meter: HeadMusic::Rudiment::Meter.get("3/4")
    #   )
    #
    # @example Converting between representations
    #   conductor = HeadMusic::Time::Conductor.new
    #   musical = HeadMusic::Time::MusicalPosition.new(2, 1, 0, 0)
    #   clock = conductor.musical_to_clock(musical)
    #   smpte = conductor.clock_to_smpte(clock)
    class Conductor
      # @return [MusicalPosition] the musical position at clock time 0
      attr_accessor :starting_musical_position

      # @return [SmpteTimecode] the SMPTE timecode at clock time 0
      attr_accessor :starting_smpte_timecode

      # @return [Integer] frames per second for SMPTE conversions
      attr_accessor :framerate

      # @return [TempoMap] the tempo map for this conductor
      attr_reader :tempo_map

      # @return [MeterMap] the meter map for this conductor
      attr_reader :meter_map

      # @return [HeadMusic::Rudiment::Tempo] the initial tempo (delegates to tempo_map)
      def starting_tempo
        tempo_map.events.first.tempo
      end

      # @return [HeadMusic::Rudiment::Meter] the initial meter (delegates to meter_map)
      def starting_meter
        meter_map.events.first.meter
      end

      # Create a new conductor
      #
      # @param starting_musical_position [MusicalPosition] initial musical position (default: 1:1:0:0)
      # @param starting_smpte_timecode [SmpteTimecode] initial SMPTE timecode (default: 00:00:00:00)
      # @param framerate [Integer] frames per second (default: 30)
      # @param starting_tempo [HeadMusic::Rudiment::Tempo] initial tempo (default: quarter = 120)
      # @param starting_meter [HeadMusic::Rudiment::Meter, String] initial meter (default: 4/4)
      # @param tempo_map [TempoMap] custom tempo map (optional, creates one from starting_tempo if not provided)
      # @param meter_map [MeterMap] custom meter map (optional, creates one from starting_meter if not provided)
      def initialize(
        starting_musical_position: nil,
        starting_smpte_timecode: nil,
        framerate: SmpteTimecode::DEFAULT_FRAMERATE,
        starting_tempo: nil,
        starting_meter: nil,
        tempo_map: nil,
        meter_map: nil
      )
        @starting_musical_position = starting_musical_position || MusicalPosition.new
        @starting_smpte_timecode = starting_smpte_timecode || SmpteTimecode.new(0, 0, 0, 0, framerate: framerate)
        @framerate = framerate

        # Create or use provided maps
        @tempo_map = tempo_map || TempoMap.new(
          starting_tempo: starting_tempo || HeadMusic::Rudiment::Tempo.new("quarter", 120),
          starting_position: @starting_musical_position
        )
        @meter_map = meter_map || MeterMap.new(
          starting_meter: starting_meter || "4/4",
          starting_position: @starting_musical_position
        )

        # Link maps together for position normalization
        @tempo_map.meter = @meter_map.meter_at(@starting_musical_position)
      end

      # Convert clock position to musical position
      #
      # Uses the tempo map to determine how many beats have elapsed,
      # accounting for tempo changes along the timeline.
      #
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

      # Convert musical position to clock position
      #
      # Uses the tempo map to determine how much clock time has elapsed
      # based on the musical position, accounting for tempo changes.
      #
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

      # Convert clock position to SMPTE timecode
      #
      # Uses the framerate to determine the timecode.
      #
      # @param clock_position [ClockPosition] the clock time to convert
      # @return [SmpteTimecode] the corresponding SMPTE timecode
      def clock_to_smpte(clock_position)
        smpte_converter.clock_to_smpte(clock_position)
      end

      # Convert SMPTE timecode to clock position
      #
      # Uses the framerate to determine the clock time.
      #
      # @param smpte_timecode [SmpteTimecode] the SMPTE timecode to convert
      # @return [ClockPosition] the corresponding clock time
      def smpte_to_clock(smpte_timecode)
        smpte_converter.smpte_to_clock(smpte_timecode)
      end

      private

      # Convert a musical position to total subticks for calculation
      #
      # @param position [MusicalPosition] the position to convert
      # @param meter [HeadMusic::Rudiment::Meter] the meter to use for calculation
      # @return [Integer] total subticks from the beginning
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
      #
      # @return [Integer] nanoseconds elapsed between start_pos and end_pos at the given tempo
      def nanoseconds_in_segment(start_pos, end_pos, tempo, meter)
        segment_subticks = musical_position_to_subticks(end_pos, meter) -
          musical_position_to_subticks(start_pos, meter)
        segment_ticks = segment_subticks / HeadMusic::Time::SUBTICKS_PER_TICK.to_f
        (segment_ticks * tempo.tick_duration_in_nanoseconds).round
      end

      # Convert an elapsed nanosecond duration into subticks at the given tempo
      #
      # @return [Integer] subticks elapsed
      def nanoseconds_to_subticks(nanoseconds, tempo)
        ticks = nanoseconds / tempo.tick_duration_in_nanoseconds.to_f
        (ticks * HeadMusic::Time::SUBTICKS_PER_TICK).round
      end

      # Decompose total subticks into a normalized bar:beat:tick:subtick position
      #
      # @return [MusicalPosition] the normalized position
      def subticks_to_musical_position(total_subticks, meter)
        subticks_per_count = meter.ticks_per_count * HeadMusic::Time::SUBTICKS_PER_TICK
        subticks_per_bar = meter.counts_per_bar * subticks_per_count

        bars, remaining = total_subticks.divmod(subticks_per_bar)
        beats, remaining = remaining.divmod(subticks_per_count)
        ticks, subticks = remaining.divmod(HeadMusic::Time::SUBTICKS_PER_TICK)

        MusicalPosition.new(bars + 1, beats + 1, ticks, subticks).normalize!(meter)
      end

      # A fresh SMPTE converter reflecting the current framerate and starting
      # timecode. Both are mutable accessors, so it is rebuilt per call rather
      # than memoized, ensuring a reassigned framerate takes effect.
      def smpte_converter
        SmpteConverter.new(framerate: framerate, starting_smpte_timecode: starting_smpte_timecode)
      end
    end
  end
end
