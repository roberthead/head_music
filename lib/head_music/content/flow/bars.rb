class HeadMusic::Content::Flow
  # A flow's bars, allocated on demand and held by number. Sparse: a bar is
  # allocated only when something asks for it, so a key change in a pickup bar
  # can allocate bar 0 while no voice places into it.
  class Bars
    def initialize(flow)
      @flow = flow
      @bars = []
    end

    # Allocates every bar from first to last and answers them in order.
    def span(first, last)
      (first..last).each do |number|
        @bars[number] ||= HeadMusic::Content::Bar.new(@flow, number: number)
      end
      @bars[first..last]
    end

    def first_number
      @bars.index { |bar| !bar.nil? }
    end

    def last_marked_number
      @bars.compact.reverse.find { |bar| bar.to_h.any? }&.number
    end

    # Key and meter changes are the timeline's, so a bar serializes its repeat
    # structure and markings, and a bar with none is left out.
    def serialize
      @bars.compact.filter_map do |bar|
        bar_hash = bar.to_h
        {"number" => bar.number}.merge(bar_hash) unless bar_hash.empty?
      end
    end
  end
end
