# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Keeps a kern file's time: which bar the reader is in, where each bar
  # starts, and whether each bar is as long as its meter says.
  #
  # Time is an exact Rational count of whole notes from the first data
  # row. Music before the first barline is a pickup, the right-aligned end
  # of the bar before it. Changes that live on bars (meter, key, tempo,
  # clef) are applied at a downbeat; one read in the middle of a bar waits
  # for the next barline, and raises if more music arrives before it.
  #
  # An unnumbered barline in the middle of a bar, such as a repeat sign
  # halfway through one, does not end the bar. Its repeat is recorded on
  # the whole bar, as ABC's RepeatTagger does.
  class BarClock
    Bar = Data.define(:number, :start)
    Pending = Data.define(:description, :line, :change)

    attr_reader :number, :bars, :repeat_starts, :repeat_ends

    def initialize(&meter_at)
      @meter_at = meter_at
      @bars = []
      @number = nil
      @bar_start = 0
      @pending = []
      @short_bar = nil
      @repeat_starts = []
      @repeat_ends = []
    end

    def barline(barline, time, line)
      elapsed = time - @bar_start
      if @number.nil?
        first_barline(barline, time, elapsed, line)
      elsif elapsed.zero?
        mark_repeats(barline, @number - 1, @number)
      elsif within_bar?(barline, elapsed)
        mark_repeats(barline, @number, @number)
      else
        close_bar(elapsed, line)
        completed = @number
        open_bar(next_number(barline, line), time)
        mark_repeats(barline, completed, @number)
      end
    end

    # Yields the bar a change takes effect in: this one when the reader is
    # at its downbeat, or else the next, once its barline arrives.
    def at_downbeat(time, description, line, &change)
      if @number && time == @bar_start
        change.call(@number)
      else
        @pending << Pending.new(description: description, line: line, change: change)
      end
    end

    # Called before music is read at a row, since music means the reader
    # has moved past the downbeat a waiting change needed.
    def ensure_music_allowed
      pending = @pending.first
      if pending
        raise UnsupportedFeatureError.new("#{pending.description} in the middle of a bar is not supported", line_number: pending.line)
      end
      return unless @short_bar

      number, line = @short_bar
      raise UnsupportedFeatureError.new(
        "Bar #{number} is shorter than its meter; only the final bar may be short", line_number: line
      )
    end

    # A file with no barlines is read as one unmeasured stretch from bar 1;
    # otherwise the last bar must not overrun its meter, though it may be
    # short.
    def finish(time, line)
      return open_bar(HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR, 0) if @number.nil?

      ensure_not_too_long(time - @bar_start, line)
    end

    def bar_containing(time)
      bars.reverse.find { |bar| bar.start <= time }
    end

    def next_bar_start(time)
      bars.find { |bar| bar.start > time }&.start
    end

    private

    def first_barline(barline, time, elapsed, line)
      number = barline.number || HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR
      open_pickup(number - 1, time, elapsed, line) if elapsed.positive?
      open_bar(number, time)
      mark_repeats(barline, number - 1, number)
    end

    def open_pickup(number, time, elapsed, line)
      raise UnsupportedFeatureError.new("A pickup before bar 0 is not supported", line_number: line) if number.negative?

      length = bar_length(number)
      raise ParseError.new("The pickup bar is longer than bar #{number}'s meter", line_number: line) if elapsed > length

      @bars << Bar.new(number: number, start: time - length)
    end

    def within_bar?(barline, elapsed)
      barline.number.nil? && !barline.final && elapsed < bar_length(@number)
    end

    # A repeat cannot end a bar that was never read.
    def mark_repeats(barline, completed, entered)
      @repeat_ends << completed if barline.ends_repeat && bars.any? { |bar| bar.number == completed }
      @repeat_starts << entered if barline.starts_repeat
    end

    def close_bar(elapsed, line)
      ensure_not_too_long(elapsed, line)
      @short_bar = [@number, line] if elapsed < bar_length(@number)
    end

    def ensure_not_too_long(elapsed, line)
      return unless elapsed > bar_length(@number)

      raise ParseError.new(
        "Bar #{@number} is too long: #{elapsed} of a whole note in #{@meter_at.call(@number)}", line_number: line
      )
    end

    def next_number(barline, line)
      expected = @number + 1
      return expected if barline.number.nil? || barline.number == expected

      raise UnsupportedFeatureError.new("Bar #{barline.number} does not follow bar #{@number}", line_number: line)
    end

    def open_bar(number, time)
      @number = number
      @bar_start = time
      @bars << Bar.new(number: number, start: time)
      @pending.each { |pending| pending.change.call(number) }
      @pending = []
    end

    def bar_length(number)
      meter = @meter_at.call(number)
      Rational(meter.top_number, meter.bottom_number)
    end
  end
end
