# A module for visual music notation
module HeadMusic::Notation
  # Aligns every part's measures into the flow's bars before any position is
  # built. A measure is as long as the longest reach of any part's notes and
  # forwards in it, whole-measure rests aside, to within the rounding one
  # division allows.
  #
  # The first measure is bar 0 when it is implicit and bar 1 otherwise, and
  # is right-aligned in its bar when short, as a pickup is. A short measure
  # that the next one completes is one bar with it, as at a repeat in the
  # middle of a bar; many exports leave the second half unmarked, so it
  # need not be implicit unless it changes the meter. The last measure may
  # be short. Any other short measure, or an overfull one, is valid notation
  # the bars cannot hold without changing the music, so it raises.
  #
  # Each bar starts where the meters of the bars before it end, so a time
  # read in a measure is exact before a single position exists. Bars are
  # numbered in order; a measure's number attribute appears only in errors.
  #
  # Each reading answers its measures, the +errors+ module whose ParseError
  # and UnsupportedFeatureError it raises, and +where+ a measure index is.
  class BarMap
    attr_reader :first_bar

    def initialize(readings)
      @readings = readings
      @bars = []
      @shifts = []
      @lengths = {}
      @meters = {}
      align
      @starts = start_times
    end

    def bar_number(measure_index)
      @bars.fetch(measure_index)
    end

    # How far into its bar a measure starts: past the rests a short first
    # measure is right-aligned behind, or past the first half of a split one.
    def shift(measure_index)
      @shifts.fetch(measure_index)
    end

    # The bar a measure after the first starts on its downbeat, nil where it
    # starts in the middle of one.
    def downbeat_bar(measure_index)
      bar_number(measure_index) if measure_index.positive? && shift(measure_index).zero?
    end

    def last_bar
      @bars.last
    end

    # Whether a measure is the second half of a bar split at a repeat.
    def split_before?(measure_index)
      measure_index.positive? && measure_index < @bars.length && @bars[measure_index] == @bars[measure_index - 1]
    end

    def start(bar_number)
      @starts.fetch(bar_number - first_bar)
    end

    # The exact time of an offset into a measure, from the first bar's start.
    def time_of(measure_index, offset)
      start(bar_number(measure_index)) + shift(measure_index) + offset
    end

    def next_bar_start(time)
      @starts.bsearch { |start| start > time }
    end

    # Where the bar a time falls in, or ends, ends: the time itself at a
    # barline, and never past the end of the music.
    def bar_end_at_or_after(time)
      [@starts.bsearch { |start| start >= time } || end_time, end_time].min
    end

    # Where the music ends: the last bar's start plus its own length, which
    # is short in a short final bar.
    def end_time
      start(last_bar) + @lengths.fetch(last_bar)
    end

    def meter_at(bar_number)
      @meters.fetch(bar_number)
    end

    def bar_numbers
      first_bar..last_bar
    end

    private

    def align
      @count = @readings.map { |reading| reading.measures.length }.max
      @first_bar = measure(0).implicit ? 0 : 1
      index = 0
      index = add_bar(index, @first_bar + @lengths.length) while index < @count
    end

    # Answers the index of the measure after the bar.
    def add_bar(index, bar)
      meter = measure(index).meter
      @meters[bar] = meter
      full = bar_length(meter)
      overfull = overfull_reading(index, full)
      raise_unsupported("is longer than its #{meter} bar", index, overfull) if overfull

      extent, *shifts = layout(index, full)
      @lengths[bar] = extent
      @shifts.concat(shifts)
      @bars.concat([bar] * shifts.length)
      index + shifts.length
    end

    # The bar's own length, then the shift of each measure it holds.
    def layout(index, full)
      length = length_of(index) || full
      return [[full, length].max, [full - length, 0].max] if index.zero?
      return [full, 0] unless beyond?(full - length, index)
      return [length, 0] if index == @count - 1
      return [full, 0, length] if completes?(index, full, length)

      raise_unsupported("is shorter than its #{measure(index).meter} bar, and no measure after it completes it", index)
    end

    def completes?(index, full, length)
      following_index = index + 1
      following = measure(following_index)
      return false unless following.implicit || following.meter == measure(index).meter

      !beyond?((length + (length_of(following_index) || 0) - full).abs, index)
    end

    def start_times
      bar_numbers.each_with_object([0]) do |bar, starts|
        starts << starts.last + bar_length(@meters.fetch(bar))
      end
    end

    def measures_at(index)
      @readings.filter_map { |reading| reading.measures[index] }
    end

    # The first part's measure, or the first that has one at this index.
    def measure(index)
      measures_at(index).first
    end

    def length_of(index)
      measures_at(index).filter_map(&:extent).max
    end

    # Whether a difference is past rounding: a whole division or more.
    def beyond?(difference, index)
      past?(difference, tolerance(index))
    end

    def past?(difference, tolerance)
      tolerance.zero? ? difference.positive? : difference >= tolerance
    end

    # The first part whose measure overfills the bar by a division of its
    # own, since another part's coarser divisions say nothing of its
    # rounding.
    def overfull_reading(index, full)
      @readings.find do |reading|
        measure = reading.measures[index]
        measure&.extent && past?(measure.extent - full, measure.tolerance)
      end
    end

    def tolerance(index)
      measures_at(index).filter_map(&:tolerance).max || 0
    end

    def bar_length(meter)
      Rational(meter.top_number, meter.bottom_number)
    end

    def raise_unsupported(problem, index, reading = @readings.find { |candidate| candidate.measures[index] })
      raise reading.errors::UnsupportedFeatureError.new("The measure #{problem}", **reading.where(index))
    end
  end
end
