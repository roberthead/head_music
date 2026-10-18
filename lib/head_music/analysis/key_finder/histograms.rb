class HeadMusic::Analysis::KeyFinder
  # Duration-weighted pitch-class histograms of a NoteInput's notes: of the
  # whole input, and of the time sounding in each bar.
  class Histograms
    def initialize(input)
      @input = input
    end

    def whole
      @input.notes.each_with_object(empty) do |note, histogram|
        histogram[note.number % 12] += note.duration
      end
    end

    # Each bar's histogram summed with +window+ bars on either side.
    def windowed(window)
      bars = by_bar
      prefix = bars.each_with_object([empty]) { |histogram, sums| sums << sums.last.zip(histogram).map(&:sum) }
      bars.each_index.map do |index|
        low = [index - window, 0].max
        high = [index + window, bars.length - 1].min
        prefix[high + 1].zip(prefix[low]).map { |upper, lower| upper - lower }
      end
    end

    # Each note's duration is credited to the bars it sounds in.
    def by_bar
      starts = @input.bar_starts.values
      index_of_bar = @input.bar_starts.keys.each_with_index.to_h
      histograms = Array.new(starts.length) { empty }
      @input.notes.each do |note|
        credit(histograms, starts, note, index_of_bar.fetch(@input.bar_at(note.onset)))
      end
      histograms
    end

    private

    def credit(histograms, starts, note, bar_index)
      from = note.onset
      finish = note.onset + note.duration
      while from < finish
        bar_end = starts[bar_index + 1]
        to = (bar_end.nil? || finish < bar_end) ? finish : bar_end
        histograms[bar_index][note.number % 12] += to - from
        from = to
        bar_index += 1
      end
    end

    def empty
      Array.new(12, 0r)
    end
  end
end
