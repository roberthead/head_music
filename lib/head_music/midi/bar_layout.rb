module HeadMusic::MIDI
  # The bars a file's time signatures lay out, from tick 0 to the end tick,
  # as exact Rational whole notes with time 0 at tick 0. Bar 0 is a pickup
  # when there is one, and the first bar is otherwise bar 1.
  class BarLayout
    Bar = Data.define(:number, :start, :length, :meter) do
      def end_time
        start + length
      end
    end

    DEFAULT_METER = "4/4"

    attr_reader :division

    # +time_signatures+ are the reader's TimeSignature events in merged order.
    def initialize(time_signatures, division:, end_tick:)
      @time_signatures = time_signatures
      @division = division
      @end_tick = end_tick
    end

    def time(tick)
      Rational(tick, division * 4)
    end

    def bars
      @bars ||= begin
        meter = HeadMusic::Rudiment::Meter.get(DEFAULT_METER)
        length = Rational(meter.top_number, meter.bottom_number)
        count = [(time(@end_tick) / length).ceil, 1].max
        Array.new(count) { |index| Bar.new(number: index + 1, start: index * length, length: length, meter: meter) }.freeze
      end
    end

    def first_number
      bars.first.number
    end

    # The bar sounding at a time; one before the first downbeat is in the
    # first bar, and one at or past the end is in the last.
    def bar_at(time)
      following = bars.bsearch_index { |bar| bar.start > time }
      return bars.last if following.nil?

      bars[[following - 1, 0].max]
    end

    def bar_starts
      @bar_starts ||= bars.to_h { |bar| [bar.number, bar.start] }.freeze
    end

    def end_time
      bars.last.end_time
    end
  end
end
