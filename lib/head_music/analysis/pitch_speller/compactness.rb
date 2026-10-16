class HeadMusic::Analysis::PitchSpeller
  # Settles the near ties among notes that start together, holding the notes
  # already sounding fixed: the narrowest span on the line of fifths, then the
  # least distance from the centers, then the sharper.
  class Compactness
    COMBINATION_LIMIT = 4096

    def initialize(pairs, centers, fixed)
      @pairs = pairs
      @centers = centers
      @low, @high = fixed.minmax
    end

    def choices
      return @pairs.map { |pair| [pair.first, :center] } if 2**@pairs.length > COMBINATION_LIMIT

      narrowest = narrowest_combinations
      winner = narrowest.min_by { |combination| [distance(combination), -combination.sum] }
      winner.each_with_index.map do |index, position|
        [index, (narrowest.all? { |combination| combination[position] == index }) ? :sonority : :center]
      end
    end

    private

    def narrowest_combinations
      combinations = (0...2**@pairs.length).map { |mask| @pairs.each_with_index.map { |pair, position| pair[mask[position]] } }
      spans = combinations.map { |combination| span(combination) }
      narrowest = spans.min
      combinations.select.with_index { |_, position| spans[position] == narrowest }
    end

    def span(combination)
      low, high = combination.minmax
      [high, @high].compact.max - [low, @low].compact.min
    end

    def distance(combination)
      combination.each_with_index.sum { |index, position| (index - @centers[position]).abs }
    end
  end
end
