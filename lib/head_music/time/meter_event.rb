# frozen_string_literal: true

module HeadMusic
  module Time
    # Represents a meter change at a specific musical position
    #
    # MeterEvent marks a point in a musical timeline where the meter
    # (time signature) changes. This is essential for properly calculating
    # musical positions and normalizing bar:beat:tick:subtick values.
    #
    # @example Creating a meter change to 3/4 at bar 5
    #   position = HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0)
    #   meter = HeadMusic::Rudiment::Meter.get("3/4")
    #   event = HeadMusic::Time::MeterEvent.new(position, meter)
    #
    # @example With common time
    #   position = HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0)
    #   meter = HeadMusic::Rudiment::Meter.common_time
    #   event = HeadMusic::Time::MeterEvent.new(position, meter)
    class MeterEvent
      # @return [MusicalPosition] the position where this meter change occurs
      attr_accessor :position

      # @return [HeadMusic::Rudiment::Meter, String] the meter (time signature)
      attr_accessor :meter

      # Create a new meter change event
      #
      # @param position [MusicalPosition] where the meter change occurs
      # @param meter [HeadMusic::Rudiment::Meter, String] the new meter
      def initialize(position, meter)
        @position = position
        @meter = meter
      end
    end
  end
end
