# frozen_string_literal: true

module HeadMusic
  module Time
    # Converts between clock time (elapsed nanoseconds) and SMPTE timecode
    # (hours:minutes:seconds:frames) at a fixed framerate. This is independent
    # of tempo and meter: only the framerate and the timecode at clock time 0
    # determine the mapping.
    class SmpteConverter
      # Nanoseconds in one second.
      NANOSECONDS_PER_SECOND = 1_000_000_000.0

      attr_reader :framerate, :starting_smpte_timecode

      def initialize(framerate:, starting_smpte_timecode:)
        @framerate = framerate
        @starting_smpte_timecode = starting_smpte_timecode
      end

      # @param clock_position [ClockPosition] the clock time to convert
      # @return [SmpteTimecode] the corresponding SMPTE timecode
      def clock_to_smpte(clock_position)
        elapsed_seconds = clock_position.nanoseconds / NANOSECONDS_PER_SECOND
        total_frames = (elapsed_seconds * framerate).round + starting_smpte_timecode.to_total_frames
        frames_to_timecode(total_frames)
      end

      # @param smpte_timecode [SmpteTimecode] the SMPTE timecode to convert
      # @return [ClockPosition] the corresponding clock time
      def smpte_to_clock(smpte_timecode)
        elapsed_frames = smpte_timecode.to_total_frames - starting_smpte_timecode.to_total_frames
        elapsed_seconds = elapsed_frames / framerate.to_f
        ClockPosition.new((elapsed_seconds * NANOSECONDS_PER_SECOND).round)
      end

      private

      # Decompose total frames into a normalized HH:MM:SS:FF timecode.
      def frames_to_timecode(total_frames)
        frames_per_minute = framerate * 60
        frames_per_hour = frames_per_minute * 60

        hours, remaining = total_frames.divmod(frames_per_hour)
        minutes, remaining = remaining.divmod(frames_per_minute)
        seconds, frames = remaining.divmod(framerate)

        SmpteTimecode.new(hours, minutes, seconds, frames, framerate: framerate).normalize!
      end
    end
  end
end
