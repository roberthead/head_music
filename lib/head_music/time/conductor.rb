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

      # @return [HeadMusic::Rudiment::Tempo] the initial tempo
      attr_accessor :starting_tempo

      # @return [HeadMusic::Rudiment::Meter] the initial meter
      attr_accessor :starting_meter

      # Create a new conductor
      #
      # @param starting_musical_position [MusicalPosition] initial musical position (default: 1:1:0:0)
      # @param starting_smpte_timecode [SmpteTimecode] initial SMPTE timecode (default: 00:00:00:00)
      # @param framerate [Integer] frames per second (default: 30)
      # @param starting_tempo [HeadMusic::Rudiment::Tempo] initial tempo (default: quarter = 120)
      # @param starting_meter [HeadMusic::Rudiment::Meter] initial meter (default: 4/4)
      def initialize(
        starting_musical_position: nil,
        starting_smpte_timecode: nil,
        framerate: SmpteTimecode::DEFAULT_FRAMERATE,
        starting_tempo: nil,
        starting_meter: nil
      )
        @starting_musical_position = starting_musical_position || MusicalPosition.new
        @starting_smpte_timecode = starting_smpte_timecode || SmpteTimecode.new(0, 0, 0, 0, framerate: framerate)
        @framerate = framerate
        @starting_tempo = starting_tempo || HeadMusic::Rudiment::Tempo.new("quarter", 120)
        @starting_meter = starting_meter || HeadMusic::Rudiment::Meter.get("4/4")
      end

      # Convert clock position to musical position
      #
      # Uses the tempo to determine how many beats have elapsed,
      # then converts to bar:beat:tick:subtick format.
      #
      # @param clock_position [ClockPosition] the clock time to convert
      # @return [MusicalPosition] the corresponding musical position
      def clock_to_musical(clock_position)
        # Calculate elapsed ticks from clock time using tempo
        elapsed_nanoseconds = clock_position.nanoseconds
        nanoseconds_per_tick = starting_tempo.tick_duration_in_nanoseconds
        elapsed_ticks = (elapsed_nanoseconds / nanoseconds_per_tick).round

        # Convert ticks to subticks (finer resolution)
        elapsed_subticks = elapsed_ticks * HeadMusic::Time::SUBTICKS_PER_TICK

        # Calculate musical position components
        ticks_per_count = starting_meter.ticks_per_count
        counts_per_bar = starting_meter.counts_per_bar
        subticks_per_count = ticks_per_count * HeadMusic::Time::SUBTICKS_PER_TICK
        subticks_per_bar = counts_per_bar * subticks_per_count

        # Start from the starting position and add elapsed time
        starting_subticks = musical_position_to_subticks(starting_musical_position)
        total_subticks = starting_subticks + elapsed_subticks

        # Convert back to bar:beat:tick:subtick
        bars = (total_subticks / subticks_per_bar).floor
        remaining = total_subticks % subticks_per_bar

        beats = (remaining / subticks_per_count).floor
        remaining %= subticks_per_count

        ticks = (remaining / HeadMusic::Time::SUBTICKS_PER_TICK).floor
        subticks = remaining % HeadMusic::Time::SUBTICKS_PER_TICK

        # Adjust for 1-indexed bars and beats
        position = MusicalPosition.new(
          bars + starting_musical_position.bar,
          beats + starting_musical_position.beat,
          ticks,
          subticks
        )
        position.normalize!(starting_meter)
      end

      # Convert musical position to clock position
      #
      # Uses the tempo to determine how much clock time has elapsed
      # based on the musical position.
      #
      # @param musical_position [MusicalPosition] the musical position to convert
      # @return [ClockPosition] the corresponding clock time
      def musical_to_clock(musical_position)
        # Calculate total subticks from start
        total_subticks = musical_position_to_subticks(musical_position)
        starting_subticks = musical_position_to_subticks(starting_musical_position)
        elapsed_subticks = total_subticks - starting_subticks

        # Convert subticks to ticks
        elapsed_ticks = elapsed_subticks / HeadMusic::Time::SUBTICKS_PER_TICK.to_f

        # Convert ticks to nanoseconds using tempo
        nanoseconds_per_tick = starting_tempo.tick_duration_in_nanoseconds
        elapsed_nanoseconds = (elapsed_ticks * nanoseconds_per_tick).round

        ClockPosition.new(elapsed_nanoseconds)
      end

      # Convert clock position to SMPTE timecode
      #
      # Uses the framerate to determine the timecode.
      #
      # @param clock_position [ClockPosition] the clock time to convert
      # @return [SmpteTimecode] the corresponding SMPTE timecode
      def clock_to_smpte(clock_position)
        # Calculate total frames from nanoseconds
        nanoseconds_per_second = 1_000_000_000.0
        elapsed_seconds = clock_position.nanoseconds / nanoseconds_per_second
        total_frames = (elapsed_seconds * framerate).round

        # Add starting timecode frames
        starting_frames = starting_smpte_timecode.to_total_frames
        total_frames += starting_frames

        # Convert frames to HH:MM:SS:FF
        hours = total_frames / (framerate * 60 * 60)
        remaining = total_frames % (framerate * 60 * 60)

        minutes = remaining / (framerate * 60)
        remaining %= (framerate * 60)

        seconds = remaining / framerate
        frames = remaining % framerate

        timecode = SmpteTimecode.new(hours, minutes, seconds, frames, framerate: framerate)
        timecode.normalize!
      end

      # Convert SMPTE timecode to clock position
      #
      # Uses the framerate to determine the clock time.
      #
      # @param smpte_timecode [SmpteTimecode] the SMPTE timecode to convert
      # @return [ClockPosition] the corresponding clock time
      def smpte_to_clock(smpte_timecode)
        # Calculate total frames
        total_frames = smpte_timecode.to_total_frames
        starting_frames = starting_smpte_timecode.to_total_frames
        elapsed_frames = total_frames - starting_frames

        # Convert frames to seconds, then to nanoseconds
        nanoseconds_per_second = 1_000_000_000.0
        elapsed_seconds = elapsed_frames / framerate.to_f
        elapsed_nanoseconds = (elapsed_seconds * nanoseconds_per_second).round

        ClockPosition.new(elapsed_nanoseconds)
      end

      private

      # Convert a musical position to total subticks for calculation
      #
      # @param position [MusicalPosition] the position to convert
      # @return [Integer] total subticks from the beginning
      def musical_position_to_subticks(position)
        ticks_per_count = starting_meter.ticks_per_count
        counts_per_bar = starting_meter.counts_per_bar

        total = 0
        total += (position.bar - 1) * counts_per_bar * ticks_per_count * HeadMusic::Time::SUBTICKS_PER_TICK
        total += (position.beat - 1) * ticks_per_count * HeadMusic::Time::SUBTICKS_PER_TICK
        total += position.tick * HeadMusic::Time::SUBTICKS_PER_TICK
        total += position.subtick

        total
      end
    end
  end
end
