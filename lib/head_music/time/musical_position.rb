# frozen_string_literal: true

module HeadMusic
  module Time
    # Representation of a musical position in bars:beats:ticks:subticks notation
    #
    # A MusicalPosition represents a point in musical time using a hierarchical
    # structure:
    # - bar: the measure number (1-indexed)
    # - beat: the beat within the bar (1-indexed)
    # - tick: subdivision of a beat (0-indexed, 960 ticks per quarter note)
    # - subtick: finest resolution (0-indexed, 240 subticks per tick)
    #
    # The position can be normalized according to a meter, which handles
    # overflow by carrying excess values to higher levels (e.g., excess ticks
    # become beats, excess beats become bars).
    #
    # @example Creating a position at bar 1, beat 1
    #   position = HeadMusic::Time::MusicalPosition.new
    #   position.to_s # => "1:1:0:0"
    #
    # @example Parsing from a string
    #   position = HeadMusic::Time::MusicalPosition.parse("2:3:480:0")
    #   position.bar # => 2
    #   position.beat # => 3
    #
    # @example Normalizing with overflow
    #   meter = HeadMusic::Rudiment::Meter.get("4/4")
    #   position = HeadMusic::Time::MusicalPosition.new(1, 1, 960, 0)
    #   position.normalize!(meter)
    #   position.to_s # => "1:2:0:0" (ticks carried into beats)
    #
    # @example Comparing positions
    #   pos1 = HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0)
    #   pos2 = HeadMusic::Time::MusicalPosition.new(1, 2, 0, 0)
    #   meter = HeadMusic::Rudiment::Meter.get("4/4")
    #   pos1.normalize!(meter)
    #   pos2.normalize!(meter)
    #   pos1 < pos2 # => true
    class MusicalPosition
      include Comparable

      # @return [Integer] the bar (measure) number (1-indexed)
      attr_reader :bar

      # @return [Integer] the beat within the bar (1-indexed)
      attr_reader :beat

      # @return [Integer] the tick within the beat (0-indexed)
      attr_reader :tick

      # @return [Integer] the subtick within the tick (0-indexed)
      attr_reader :subtick

      # Default starting bar number
      DEFAULT_FIRST_BAR = 1

      # First beat in a bar
      FIRST_BEAT = 1

      # First tick in a beat
      FIRST_TICK = 0

      # First subtick in a tick
      FIRST_SUBTICK = 0

      # Parse a position from a string representation
      #
      # @param identifier [String] position in "bar:beat:tick:subtick" format
      # @return [MusicalPosition] the parsed position
      # @example
      #   MusicalPosition.parse("2:3:480:120")
      def self.parse(identifier)
        new(*identifier.scan(/\d+/)[0..3])
      end

      # Create a new musical position
      #
      # @param bar [Integer, String] the bar number (default: 1)
      # @param beat [Integer, String] the beat number (default: 1)
      # @param tick [Integer, String] the tick number (default: 0)
      # @param subtick [Integer, String] the subtick number (default: 0)
      def initialize(
        bar = DEFAULT_FIRST_BAR,
        beat = FIRST_BEAT,
        tick = FIRST_TICK,
        subtick = FIRST_SUBTICK
      )
        @bar = bar.to_i
        @beat = beat.to_i
        @tick = tick.to_i
        @subtick = subtick.to_i
        @meter = nil
        @total_subticks = nil
      end

      # Convert position to array format
      #
      # @return [Array<Integer>] [bar, beat, tick, subtick]
      def to_a
        [bar, beat, tick, subtick]
      end

      # Convert position to string format
      #
      # @return [String] position in "bar:beat:tick:subtick" format
      def to_s
        "#{bar}:#{beat}:#{tick}:#{subtick}"
      end

      # Normalize the position according to a meter, handling overflow
      #
      # This method modifies the position in place, carrying excess values
      # from lower levels to higher levels (subticks → ticks → beats → bars).
      # Also handles negative values by borrowing from higher levels.
      #
      # @param meter [HeadMusic::Rudiment::Meter, nil] the meter to use for normalization
      # @return [self] returns self for method chaining
      # @example
      #   meter = HeadMusic::Rudiment::Meter.get("4/4")
      #   position = MusicalPosition.new(1, 1, 960, 240)
      #   position.normalize!(meter) # => "1:2:1:0"
      def normalize!(meter)
        return self unless meter

        @meter = meter
        @total_subticks = nil # Invalidate cached value

        # Carry subticks into ticks
        if subtick >= HeadMusic::Time::SUBTICKS_PER_TICK || subtick.negative?
          tick_delta, @subtick = subtick.divmod(HeadMusic::Time::SUBTICKS_PER_TICK)
          @tick += tick_delta
        end

        # Carry ticks into beats
        if tick >= meter.ticks_per_count || tick.negative?
          beat_delta, @tick = tick.divmod(meter.ticks_per_count)
          @beat += beat_delta
        end

        # Carry beats into bars
        if beat >= meter.counts_per_bar || beat.negative?
          bar_delta, @beat = beat.divmod(meter.counts_per_bar)
          @bar += bar_delta
        end

        self
      end

      # Compare this position to another
      #
      # Note: For accurate comparison, both positions should be normalized
      # with the same meter first.
      #
      # @param other [MusicalPosition] another position to compare
      # @return [Integer] -1 if less than, 0 if equal, 1 if greater than
      def <=>(other)
        to_total_subticks <=> other.to_total_subticks
      end

      # Convert position to total subticks for comparison and calculation
      #
      # @return [Integer] total subticks from the beginning
      # @note This calculation assumes the position has been normalized
      def to_total_subticks
        return @total_subticks if @total_subticks

        # Calculate based on the structure
        # Note: This is a simplified calculation that assumes consistent meter
        ticks_per_count = @meter&.ticks_per_count || HeadMusic::Time::PPQN
        counts_per_bar = @meter&.counts_per_bar || 4

        total = 0
        total += (bar - 1) * counts_per_bar * ticks_per_count * HeadMusic::Time::SUBTICKS_PER_TICK
        total += (beat - 1) * ticks_per_count * HeadMusic::Time::SUBTICKS_PER_TICK
        total += tick * HeadMusic::Time::SUBTICKS_PER_TICK
        total += subtick

        @total_subticks = total
      end

      protected

      # Allow other MusicalPosition instances to access this method for comparison
      alias_method :to_i, :to_total_subticks
    end
  end
end
