# frozen_string_literal: true

module HeadMusic
  module Time
    # A value object representing elapsed nanoseconds of clock time
    #
    # ClockPosition provides a high-precision representation of time elapsed
    # from a reference point, stored as nanoseconds. This allows for precise
    # temporal calculations in musical contexts where millisecond-level accuracy
    # is required for MIDI timing, audio synchronization, and SMPTE timecode.
    #
    # @example Creating a position at one second
    #   position = HeadMusic::Time::ClockPosition.new(1_000_000_000)
    #   position.to_seconds # => 1.0
    #
    # @example Adding two positions together
    #   pos1 = HeadMusic::Time::ClockPosition.new(500_000_000)
    #   pos2 = HeadMusic::Time::ClockPosition.new(300_000_000)
    #   result = pos1 + pos2
    #   result.to_milliseconds # => 800.0
    #
    # @example Comparing positions
    #   early = HeadMusic::Time::ClockPosition.new(1_000_000_000)
    #   late = HeadMusic::Time::ClockPosition.new(2_000_000_000)
    #   early < late # => true
    class ClockPosition
      include Comparable

      # @return [Integer] the number of nanoseconds since the reference point
      attr_reader :nanoseconds

      # Create a new clock position
      #
      # @param nanoseconds [Integer] the number of nanoseconds elapsed
      def initialize(nanoseconds)
        @nanoseconds = nanoseconds
      end

      # Convert to integer representation (nanoseconds)
      #
      # @return [Integer] nanoseconds
      def to_i
        nanoseconds
      end

      # Convert nanoseconds to microseconds
      #
      # @return [Float] elapsed microseconds
      def to_microseconds
        nanoseconds / 1_000.0
      end

      # Convert nanoseconds to milliseconds
      #
      # @return [Float] elapsed milliseconds
      def to_milliseconds
        nanoseconds / 1_000_000.0
      end

      # Convert nanoseconds to seconds
      #
      # @return [Float] elapsed seconds
      def to_seconds
        nanoseconds / 1_000_000_000.0
      end

      # Add another clock position to this one
      #
      # @param other [ClockPosition, #to_i] another position or value with nanoseconds
      # @return [ClockPosition] a new position with the combined duration
      def +(other)
        self.class.new(nanoseconds + other.to_i)
      end

      # Compare this position to another
      #
      # @param other [ClockPosition, #to_i] another position to compare
      # @return [Integer] -1 if less than, 0 if equal, 1 if greater than
      def <=>(other)
        nanoseconds <=> other.to_i
      end
    end
  end
end
