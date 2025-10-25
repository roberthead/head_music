# frozen_string_literal: true

module HeadMusic
  module Time
    # Represents a SMPTE (Society of Motion Picture and Television Engineers) timecode
    #
    # SMPTE timecode is used for synchronizing audio and video in professional
    # production. It represents time as HH:MM:SS:FF (hours:minutes:seconds:frames).
    #
    # The framerate determines how many frames occur per second. Common framerates:
    # - 24 fps: Film standard
    # - 25 fps: PAL video standard (Europe)
    # - 30 fps: NTSC video standard (North America)
    # - 29.97 fps: NTSC drop-frame
    #
    # @example Creating a timecode at 1 hour
    #   timecode = HeadMusic::Time::SmpteTimecode.new(1, 0, 0, 0)
    #   timecode.to_s # => "01:00:00:00"
    #
    # @example Parsing from a string
    #   timecode = HeadMusic::Time::SmpteTimecode.parse("02:30:45:15")
    #   timecode.hour # => 2
    #   timecode.minute # => 30
    #
    # @example Normalizing with overflow
    #   timecode = HeadMusic::Time::SmpteTimecode.new(0, 0, 0, 60, framerate: 30)
    #   timecode.normalize!
    #   timecode.to_s # => "00:00:02:00" (frames carried into seconds)
    #
    # @example Comparing timecodes
    #   tc1 = HeadMusic::Time::SmpteTimecode.new(1, 0, 0, 0)
    #   tc2 = HeadMusic::Time::SmpteTimecode.new(1, 30, 0, 0)
    #   tc1 < tc2 # => true
    class SmpteTimecode
      include Comparable

      # @return [Integer] the hour component
      attr_reader :hour

      # @return [Integer] the minute component
      attr_reader :minute

      # @return [Integer] the second component
      attr_reader :second

      # @return [Integer] the frame component
      attr_reader :frame

      # @return [Integer] frames per second (default: 30 for NTSC)
      attr_reader :framerate

      # Default framerate (30 fps NTSC)
      DEFAULT_FRAMERATE = 30

      # Seconds per minute
      SECONDS_PER_MINUTE = 60

      # Minutes per hour
      MINUTES_PER_HOUR = 60

      # Parse a timecode from a string representation
      #
      # @param identifier [String] timecode in "HH:MM:SS:FF" format
      # @return [SmpteTimecode] the parsed timecode
      # @example
      #   SmpteTimecode.parse("02:30:45:15")
      def self.parse(identifier)
        new(*identifier.scan(/\d+/)[0..3])
      end

      # Create a new SMPTE timecode
      #
      # @param hour [Integer, String] the hour component (default: 0)
      # @param minute [Integer, String] the minute component (default: 0)
      # @param second [Integer, String] the second component (default: 0)
      # @param frame [Integer, String] the frame component (default: 0)
      # @param framerate [Integer] frames per second (default: 30)
      def initialize(hour = 0, minute = 0, second = 0, frame = 0, framerate: DEFAULT_FRAMERATE)
        @hour = hour.to_i
        @minute = minute.to_i
        @second = second.to_i
        @frame = frame.to_i
        @framerate = framerate
        @total_frames = nil
      end

      # Convert timecode to array format
      #
      # @return [Array<Integer>] [hour, minute, second, frame]
      def to_a
        [hour, minute, second, frame]
      end

      # Convert timecode to string format with zero padding
      #
      # @return [String] timecode in "HH:MM:SS:FF" format
      def to_s
        format("%02d:%02d:%02d:%02d", hour, minute, second, frame)
      end

      # Normalize the timecode, handling overflow and underflow
      #
      # This method modifies the timecode in place, carrying excess values
      # from lower levels to higher levels (frames → seconds → minutes → hours).
      # Also handles negative values by borrowing from higher levels.
      #
      # @return [self] returns self for method chaining
      # @example
      #   timecode = SmpteTimecode.new(0, 0, 0, 60, framerate: 30)
      #   timecode.normalize! # => "00:00:02:00"
      def normalize!
        @total_frames = nil # Invalidate cached value

        # Carry frames into seconds
        if frame >= framerate || frame.negative?
          second_delta, @frame = frame.divmod(framerate)
          @second += second_delta
        end

        # Carry seconds into minutes
        if second >= SECONDS_PER_MINUTE || second.negative?
          minute_delta, @second = second.divmod(SECONDS_PER_MINUTE)
          @minute += minute_delta
        end

        # Carry minutes into hours
        if minute >= MINUTES_PER_HOUR || minute.negative?
          hour_delta, @minute = minute.divmod(MINUTES_PER_HOUR)
          @hour += hour_delta
        end

        self
      end

      # Compare this timecode to another
      #
      # @param other [SmpteTimecode] another timecode to compare
      # @return [Integer] -1 if less than, 0 if equal, 1 if greater than
      def <=>(other)
        to_total_frames <=> other.to_total_frames
      end

      # Convert timecode to total frames from the beginning
      #
      # @return [Integer] total frames
      def to_total_frames
        return @total_frames if @total_frames

        total = 0
        total += hour * MINUTES_PER_HOUR * SECONDS_PER_MINUTE * framerate
        total += minute * SECONDS_PER_MINUTE * framerate
        total += second * framerate
        total += frame

        @total_frames = total
      end

      protected

      # Allow other SmpteTimecode instances to access this method for comparison
      alias_method :to_i, :to_total_frames
    end
  end
end
