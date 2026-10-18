module HeadMusic::MIDI
  # The meters a file's time signatures put in force, as [time, meter] pairs
  # in Rational whole notes: one at time 0, and one wherever a later time
  # signature takes effect before the end, the last at a tick winning. Each
  # snaps to the grid point within a tick of it, counted from the one before,
  # since writers that count in ticks round a short bar.
  class MeterChanges
    DEFAULT_METER = "4/4"
    # The finest automatic grids, sixty-fourths and their triplet division,
    # since export writes a triplet pickup's barline on a triplet point.
    SIGNATURE_STEPS = [Rational(1, 64), Rational(1, 96)].freeze

    # +time_signatures+ are the reader's TimeSignature events in merged order.
    def initialize(time_signatures, division:, end_tick:)
      @time_signatures = time_signatures
      @division = division
      @end_tick = end_tick
    end

    def to_a
      @changes ||= read.freeze
    end

    # The second time signature arrives within the first bar and before a
    # full bar of its own meter, so the bar it closes is a pickup.
    def pickup?
      return false if to_a.length < 2

      at, following = to_a[1]
      at <= BarLayout.length(to_a.first.last) && at < BarLayout.length(following)
    end

    # The changes after any pickup, each to a meter other than the one before.
    def sections
      @sections ||= to_a.drop(pickup? ? 1 : 0).chunk_while { |before, after| before.last == after.last }.map(&:first).freeze
    end

    def barline?(time)
      from, meter = sections.reverse.find { |at, _meter| at <= time }
      !from.nil? && ((time - from) / BarLayout.length(meter)).denominator == 1
    end

    private

    def read
      latest = @time_signatures.chunk_while { |before, after| before.tick == after.tick }.map(&:last)
      changes = [[0r, HeadMusic::Rudiment::Meter.get(DEFAULT_METER)]]
      latest.each do |event|
        next unless event.tick < @end_tick || event.tick.zero?

        at = event.tick.zero? ? 0r : snap(event.tick, changes.last.first)
        changes.pop if changes.last.first == at
        changes << [at, HeadMusic::Rudiment::Meter.get("#{event.numerator}/#{event.denominator}")]
      end
      changes
    end

    def snap(tick, from)
      offset = Rational(tick, @division * 4) - from
      point = SIGNATURE_STEPS.map { |step| (offset / step).round * step }.min_by { |candidate| (offset - candidate).abs }
      return from + point if ((offset - point) * @division * 4).abs <= 1

      raise UnsupportedFeatureError, "the time signature at tick #{tick} falls between grid points, " \
        "more than a tick from any sixty-fourth or triplet sixty-fourth after the one before"
    end
  end
end
