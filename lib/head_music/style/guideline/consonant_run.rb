module HeadMusic::Style; end

class HeadMusic::Style::Guideline
  # A passing or neighbor figure of any length: the stepwise run through a
  # note, out to the nearest consonant notes in both directions, moving in one
  # direction (passing) or returning to its starting pitch (neighbor). A rest
  # breaks the run.
  class ConsonantRun
    def initialize(line:, note:, dissonant:)
      @line = line
      @note = note
      @dissonant = dissonant
    end

    def passing?
      stepwise? && intervals.map(&:direction).uniq.one?
    end

    def returning?
      stepwise? && notes.first.pitch == notes.last.pitch
    end

    private

    def stepwise?
      intervals.any? && intervals.all?(&:step?)
    end

    def intervals
      @intervals ||= notes.each_cons(2).map { |pair| HeadMusic::Analysis::MelodicInterval.new(*pair) }
    end

    # None where the phrase has no consonant note on one side of the note.
    def notes
      @notes ||= begin
        index = phrase.index(@note)
        first = phrase.take(index).rindex { |candidate| consonant?(candidate) }
        last = phrase.drop(index + 1).index { |candidate| consonant?(candidate) }
        (first && last) ? phrase[first..(index + 1 + last)] : []
      end
    end

    def phrase
      @phrase ||= @line
        .slice_when { |earlier, later| earlier.next_position < later.position }
        .detect { |group| group.include?(@note) }
    end

    def consonant?(candidate)
      !@dissonant.call(candidate)
    end
  end
end
