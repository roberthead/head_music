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
    # The finest automatic grids, sixty-fourths and their triplet division,
    # since export writes a triplet pickup's barline on a triplet point.
    SIGNATURE_STEPS = [Rational(1, 64), Rational(1, 96)].freeze

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
      @time_signatures = time_signatures
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

    def bar_starts
      @bar_starts ||= bars.to_h { |bar| [bar.number, bar.start] }.freeze
    end

    def end_time
      bars.last.end_time
    end

    # [time, meter] at time 0 and wherever a later time signature takes
    # effect before the end, the last at a tick winning. Each snaps to the
    # grid point within a tick of it, counted from the one before, since
    # writers that count in ticks round a short bar.
    def meter_changes
      @meter_changes ||= begin
        latest = @time_signatures.chunk_while { |before, after| before.tick == after.tick }.map(&:last)
        changes = [[0r, HeadMusic::Rudiment::Meter.get(DEFAULT_METER)]]
        latest.each do |event|
          next unless event.tick < @end_tick || event.tick.zero?

          at = event.tick.zero? ? 0r : snap(event.tick, changes.last.first)
          changes.pop if changes.last.first == at
          changes << [at, HeadMusic::Rudiment::Meter.get("#{event.numerator}/#{event.denominator}")]
        end
        changes.freeze
      end
    end

    # Worked out from the meter changes, without laying out the bars.
    def barline?(time)
      changes = meter_changes
      changes = changes.drop(1) if pickup?(changes)
      from, meter = changes.chunk_while { |before, after| before.last == after.last }.map(&:first).reverse.find { |at, _meter| at <= time }
      !from.nil? && ((time - from) / length_of(meter)).denominator == 1
    end

    private

    def lay_out
      changes = meter_changes
      bars = []
      start = 0r
      if pickup?(changes)
        bars << Bar.new(number: 0, start: start, length: changes[1].first, meter: changes[1].last)
        start = changes[1].first
        changes = changes.drop(1)
      end
      meter = changes.first.last
      changes.drop(1).each do |at, following|
        next if following == meter

        start = fill(bars, start, at, meter, partial: false)
        meter = following
      end
      fill(bars, start, [time(@end_tick), start].max, meter, partial: true)
      bars << bar(bars, start, meter) if bars.empty?
      bars
    end

    def snap(tick, from)
      offset = time(tick) - from
      point = SIGNATURE_STEPS.map { |step| (offset / step).round * step }.min_by { |candidate| (offset - candidate).abs }
      return from + point if ((offset - point) * division * 4).abs <= 1

      raise UnsupportedFeatureError, "the time signature at tick #{tick} falls between grid points, " \
        "more than a tick from any sixty-fourth or triplet sixty-fourth after the one before"
    end

    # The second time signature arrives within the first bar and before a
    # full bar of its own meter, so the bar it closes is a pickup.
    def pickup?(changes)
      return false if changes.length < 2

      at, following = changes[1]
      at <= length_of(changes.first.last) && at < length_of(following)
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
