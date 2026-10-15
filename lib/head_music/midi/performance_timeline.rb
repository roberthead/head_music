module HeadMusic::MIDI
  # The bars as played, laid end to end. Times are exact Rational whole notes
  # from the file's start, never the rounded subticks of a position.
  class PerformanceTimeline
    # +window_from+ is where in its bar the span starts sounding: past the
    # silence before a pickup's first note, and 0 otherwise.
    PlayedSpan = Data.define(:played_bar, :start, :window_from, :length) do
      def bar_number
        played_bar.number
      end

      def pass
        played_bar.pass
      end

      def finish
        start + length
      end

      # The file time of an offset into the bar.
      def time_at(offset)
        start + offset - window_from
      end

      def pickup?
        window_from.positive?
      end
    end

    attr_reader :flow, :spans

    def self.bar_length(flow, bar_number)
      meter = flow.meter_at(bar_number)
      Rational(meter.top_number, meter.bottom_number)
    end

    def initialize(flow, played_bars = flow.performance_order)
      @flow = flow
      @spans = lay_out(played_bars)
    end

    def finish
      spans.empty? ? 0 : spans.last.finish
    end

    # Whether the span after this one plays the next bar of the score, so a
    # note held over the barline sounds on into it.
    def continues_after?(index)
      following = spans[index + 1]
      following ? following.bar_number == spans[index].bar_number + 1 : false
    end

    private

    def lay_out(played_bars)
      start = 0
      played_bars.map do |played_bar|
        number = played_bar.number
        window_from = (number < 1) ? pickup_start(number) : 0
        span = PlayedSpan.new(played_bar, start, window_from, self.class.bar_length(flow, number) - window_from)
        start = span.finish
        span
      end
    end

    # A pickup sounds from its first note; the rests before it pad the bar.
    def pickup_start(bar_number)
      @pickup_starts ||= {}
      @pickup_starts[bar_number] ||= first_onset_in(bar_number)
    end

    def first_onset_in(bar_number)
      onsets = flow.voices.flat_map(&:note_events).filter_map do |voice_event|
        bar, offset = HeadMusic::Notation::BarSplitter.exact_start(voice_event)
        offset if bar == bar_number
      end
      onsets.min || self.class.bar_length(flow, bar_number)
    end
  end
end
