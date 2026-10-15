# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Aligns every part's measures into the flow's bars before any position is
  # built. A bar is as long as the longest reach of any part's notes and
  # forwards in it, whole-measure rests aside. The first measure is bar 0
  # when it is implicit and bar 1 otherwise, and is right-aligned in its bar
  # when short, as a pickup is.
  #
  # Each bar starts where the meters of the bars before it end, so a time
  # read in a measure is exact before a single position exists.
  class BarMap
    attr_reader :first_bar, :meters

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

    def last_bar
      @bars.last
    end

    def start(bar_number)
      @starts.fetch(bar_number - first_bar)
    end

    # The exact time of an offset into a measure, from the first bar's start.
    def time_of(measure_index, offset)
      start(bar_number(measure_index)) + @shifts.fetch(measure_index) + offset
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

    private

    def align
      measure_count = @readings.map { |reading| reading.measures.length }.max
      @first_bar = first_measure(0)&.implicit ? 0 : 1
      bar = @first_bar
      (0...measure_count).each do |index|
        meter = meter_of(index)
        length = length_of(index) || bar_length(meter)
        @bars << bar
        @shifts << ((index.zero? && length < bar_length(meter)) ? bar_length(meter) - length : 0)
        @lengths[bar] = index.zero? ? [length, bar_length(meter)].max : length
        @meters[bar] = meter
        bar += 1
      end
    end

    def start_times
      (@first_bar..last_bar).each_with_object([0]) do |bar, starts|
        starts << starts.last + bar_length(@meters.fetch(bar))
      end
    end

    def first_measure(index)
      @readings.lazy.filter_map { |reading| reading.measures[index] }.first
    end

    def meter_of(index)
      first_measure(index).meter
    end

    def length_of(index)
      @readings.filter_map { |reading| reading.measures[index]&.extent }.max
    end

    def bar_length(meter)
      Rational(meter.top_number, meter.bottom_number)
    end
  end
end
