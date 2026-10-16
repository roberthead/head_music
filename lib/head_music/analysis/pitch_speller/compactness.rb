class HeadMusic::Analysis::PitchSpeller
  # Settles the near ties among notes that start together, holding the notes
  # already sounding fixed: the narrowest span on the line of fifths, then the
  # least distance from the centers, then the sharper.
  #
  # Doublings of a pitch class share a pair of candidates, and splitting them
  # between the two would only widen the span, so each distinct pair is settled
  # once, weighted by its doublings. At most twelve pitch classes bound the
  # combinations at 4,096.
  class Compactness
    def initialize(pairs, centers, fixed)
      @notes = pairs.zip(centers)
      @distinct = @notes.tally.to_a
      @low, @high = fixed.minmax
    end

    def choices
      narrowest = narrowest_combinations
      winner = narrowest.min_by { |combination| [distance(combination), -weighted_sum(combination)] }
      settled = @distinct.each_with_index.to_h do |(note, _), position|
        [note, [winner[position], (narrowest.all? { |combination| combination[position] == winner[position] }) ? :sonority : :center]]
      end
      @notes.map { |note| settled.fetch(note) }
    end

    private

    def narrowest_combinations
      combinations = (0...2**@distinct.length).map do |mask|
        @distinct.each_with_index.map { |((pair, _), _), position| pair[mask[position]] }
      end
      spans = combinations.map { |combination| span(combination) }
      narrowest = spans.min
      combinations.select.with_index { |_, position| spans[position] == narrowest }
    end

    def span(combination)
      low, high = combination.minmax
      [high, @high].compact.max - [low, @low].compact.min
    end

    def distance(combination)
      combination.each_with_index.sum do |index, position|
        (_, center), count = @distinct[position]
        count * (index - center).abs
      end
    end

    def weighted_sum(combination)
      combination.each_with_index.sum { |index, position| @distinct[position].last * index }
    end
  end
end
