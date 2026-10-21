module HeadMusic::MIDI
  # The bars a file's time signatures lay out, from tick 0 to the end tick,
  # as exact Rational whole notes with time 0 at tick 0. Bar 0 is a pickup
  # when there is one, and the first bar is otherwise bar 1.
  class BarLayout
    Bar = Data.define(:number, :start, :length, :meter) do
      def end_time
        start + length
      end

      # The bar of the same length and meter so many bars on.
      def later(count)
        with(number: number + count, start: start + (count * length))
      end

      # The beats from the downbeat the bar counts from to a time. A short
      # bar is the end of a full one, so its downbeat lies before its start.
      def beat_count(time)
        offset(time) / beat
      end

      # The whole notes from the downbeat the bar counts from to a time.
      def offset(time)
        time - downbeat
      end

      def beat_time(count)
        downbeat + (count * beat)
      end

      def beat
        BarLayout.beat(meter).fraction
      end

      private

      def downbeat
        nominal = BarLayout.length(meter)
        (length < nominal) ? end_time - nominal : start
      end
    end

    # The meter's beat. Meter gives a compound meter of whole notes, such as
    # 6/1, a beat with no unit, since writers beam nothing under it; a MIDI
    # file may carry one, and it beats in dotted double wholes.
    def self.beat(meter)
      beat = meter.beat_value
      return beat if beat.unit

      HeadMusic::Rudiment::RhythmicValue.new(HeadMusic::Rudiment::RhythmicUnit.get("double whole"), dots: 1)
    end

    def self.length(meter)
      Rational(meter.top_number, meter.bottom_number)
    end

    attr_reader :division

    # +time_signatures+ are the reader's TimeSignature events in merged order.
    def initialize(time_signatures, division:, end_tick:)
      @meters = MeterChanges.new(time_signatures, division: division, end_tick: end_tick)
      @division = division
      @end_tick = end_tick
    end

    def time(tick)
      Rational(tick, division * 4)
    end

    def bars
      @bars ||= lay_out.freeze
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

    # Whether a bar starts at a time; the end is no downbeat.
    def downbeat?(time)
      time < end_time && bar_at(time).start == time
    end

    def bar_starts
      @bar_starts ||= bars.to_h { |bar| [bar.number, bar.start] }.freeze
    end

    def end_time
      bars.last.end_time
    end

    # [time, meter] at time 0 and wherever a later time signature takes
    # effect before the end.
    def meter_changes
      @meters.to_a
    end

    # Worked out from the meter changes, without laying out the bars.
    def barline?(time)
      @meters.barline?(time)
    end

    private

    def lay_out
      bars = []
      start = 0r
      if @meters.pickup?
        start, meter = meter_changes[1]
        bars << Bar.new(number: 0, start: 0r, length: start, meter: meter)
      end
      sections = @meters.sections
      sections.each_cons(2) { |(_, meter), (at, _)| start = fill(bars, start, at, meter, partial: false) }
      meter = sections.last.last
      fill(bars, start, [time(@end_tick), start].max, meter, partial: true)
      bars << bar(bars, start, meter) if bars.empty?
      bars
    end

    # Appends the bars of one meter from +start+ to +to+, which must be a
    # barline unless it is the end, and returns where they end.
    def fill(bars, start, to, meter, partial:)
      count = (to - start) / length_of(meter)
      raise UnsupportedFeatureError, "a time signature changes the meter within bar #{next_number(bars) + count.floor}" unless partial || count.denominator == 1

      count.ceil.times { |index| bars << bar(bars, start + index * length_of(meter), meter) }
      start + count.ceil * length_of(meter)
    end

    def bar(bars, start, meter)
      Bar.new(number: next_number(bars), start: start, length: length_of(meter), meter: meter)
    end

    def next_number(bars)
      bars.empty? ? 1 : bars.last.number + 1
    end

    def length_of(meter)
      self.class.length(meter)
    end
  end
end
