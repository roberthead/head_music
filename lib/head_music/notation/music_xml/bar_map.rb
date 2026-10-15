# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Aligns every part's measures into the flow's bars before any position is
  # built. A measure is as long as the longest reach of any part's notes and
  # forwards in it, whole-measure rests aside, to within the rounding one
  # division allows.
  #
  # The first measure is bar 0 when it is implicit and bar 1 otherwise, and
  # is right-aligned in its bar when short, as a pickup is. A short measure
  # that an implicit one completes is one bar with it, as at a repeat in the
  # middle of a bar, and the last measure may be short. Any other short
  # measure, or an overfull one, is valid MusicXML the bars cannot hold
  # without changing the music, so it raises.
  #
  # Each bar starts where the meters of the bars before it end, so a time
  # read in a measure is exact before a single position exists. Bars are
  # numbered in order; a measure's number attribute appears only in errors.
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
      full = bar_length(meter)
      length = length_of(index) || full
      @meters[bar] = meter
      @bars << bar
      raise_unsupported("is longer than its #{meter} bar", index) if beyond?(length - full, index)
      return add_first_bar(full, length) if index.zero?

      short = beyond?(full - length, index)
      if short && index < @count - 1
        return add_split_bar(index, bar, full, length) if completes?(index, full, length)

        raise_unsupported("is shorter than its #{meter} bar, and no implicit measure completes it", index)
      end
      @shifts << 0
      @lengths[bar] = short ? length : full
      index + 1
    end

    def add_first_bar(full, length)
      @shifts << [full - length, 0].max
      @lengths[@first_bar] = [full, length].max
      1
    end

    def add_split_bar(index, bar, full, length)
      @bars << bar
      @shifts.push(0, length)
      @lengths[bar] = full
      index + 2
    end

    def completes?(index, full, length)
      following = measure(index + 1)
      following.implicit && !beyond?(((length + (length_of(index + 1) || 0)) - full).abs, index)
    end

    def start_times
      bar_numbers.each_with_object([0]) do |bar, starts|
        starts << starts.last + bar_length(@meters.fetch(bar))
      end
    end

    # The first part's measure, or the first that has one at this index.
    def measure(index)
      @readings.lazy.filter_map { |reading| reading.measures[index] }.first
    end

    def length_of(index)
      @readings.filter_map { |reading| reading.measures[index]&.extent }.max
    end

    # Whether a difference is past rounding: a whole division or more.
    def beyond?(difference, index)
      tolerance = tolerance(index)
      tolerance.zero? ? difference.positive? : difference >= tolerance
    end

    def tolerance(index)
      @readings.filter_map { |reading| reading.measures[index]&.tolerance }.max || 0
    end

    def bar_length(meter)
      Rational(meter.top_number, meter.bottom_number)
    end

    def raise_unsupported(problem, index)
      reading = @readings.find { |candidate| candidate.measures[index] }
      raise UnsupportedFeatureError.new("The measure #{problem}", measure: reading.measures[index].number, part: reading.id)
    end
  end
end
