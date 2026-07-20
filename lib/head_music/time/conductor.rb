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
        musical_time_converter.clock_to_musical(clock_position)
      end

      # Convert musical position to clock position
      #
      # Uses the tempo map to determine how much clock time has elapsed
      # based on the musical position, accounting for tempo changes.
      #
      # @param musical_position [MusicalPosition] the musical position to convert
      # @return [ClockPosition] the corresponding clock time
      def musical_to_clock(musical_position)
        musical_time_converter.musical_to_clock(musical_position)
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

      # A fresh musical-time converter over the current maps and starting
      # position (starting_musical_position is a mutable accessor), rebuilt per
      # call rather than memoized so reassignment takes effect.
      def musical_time_converter
        MusicalTimeConverter.new(
          tempo_map: tempo_map,
          meter_map: meter_map,
          starting_musical_position: starting_musical_position
        )
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
