class HeadMusic::Analysis::KeyFinder
  # The key index for each bar that maximizes the summed scores, less the
  # change penalty for every change of key: Viterbi over bars and keys. A tie
  # keeps the key in force, then goes by preference. A bar that
  # scores nothing changes no key, so a change waits for the music.
  class KeyPath
    def initialize(scores, change_penalty:, preference:)
      @scores = scores
      @change_penalty = change_penalty
      @preference = preference
    end

    def to_a
      totals = @scores.first.dup
      back_pointers = @scores.drop(1).map do |bar_scores|
        next totals.each_index.to_a if bar_scores.all?(&:zero?)

        pointers = pointers_from(totals)
        totals = pointers.each_with_index.map { |from, index| totals[from] - ((from == index) ? 0 : @change_penalty) + bar_scores[index] }
        pointers
      end
      path = [best_index(totals)]
      back_pointers.reverse_each { |pointers| path.unshift(pointers[path.first]) }
      path
    end

    private

    def pointers_from(totals)
      leader = best_index(totals)
      moved = totals[leader] - @change_penalty
      totals.each_index.map { |index| (totals[index] >= moved) ? index : leader }
    end

    def best_index(totals)
      totals.each_index.min_by { |index| [-totals[index], *@preference[index]] }
    end
  end
end
