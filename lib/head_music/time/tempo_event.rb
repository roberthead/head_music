# frozen_string_literal: true

module HeadMusic
  module Time
    # Represents a tempo change at a specific musical position
    #
    # TempoEvent marks a point in a musical timeline where the tempo changes.
    # This is essential for converting between clock time and musical position,
    # as different tempos affect how long each beat takes in real time.
    #
    # @example Creating a tempo change to quarter = 120 at bar 1
    #   position = HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0)
    #   event = HeadMusic::Time::TempoEvent.new(position, "quarter", 120)
    #
    # @example With a dotted quarter note tempo
    #   position = HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0)
    #   event = HeadMusic::Time::TempoEvent.new(position, "dotted quarter", 92)
    #
    # @example With an eighth note tempo
    #   position = HeadMusic::Time::MusicalPosition.new(10, 1, 0, 0)
    #   event = HeadMusic::Time::TempoEvent.new(position, "eighth", 140)
    class TempoEvent
      # @return [MusicalPosition] the position where this tempo change occurs
      attr_accessor :position

      # @return [HeadMusic::Rudiment::Tempo] the tempo
      attr_accessor :tempo

      # Create a new tempo change event
      #
      # @param position [MusicalPosition] where the tempo change occurs
      # @param beat_value [String] the rhythmic value that gets the beat (e.g., "quarter", "eighth")
      # @param beats_per_minute [Numeric] the tempo in beats per minute
      def initialize(position, beat_value, beats_per_minute)
        @position = position
        @tempo = HeadMusic::Rudiment::Tempo.new(beat_value, beats_per_minute)
      end
    end
  end
end
