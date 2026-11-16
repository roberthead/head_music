module HeadMusic::Style; end

class HeadMusic::Style::Guideline
  # The ornamental figures a dissonant note can belong to in one line: passing
  # tone, neighbor tone, nota cambiata, and double neighbor. The line is given
  # as its notes and melodic intervals; the dissonance test is given as a
  # callable, so the same figures can be read in a voice moving against a
  # cantus firmus or against another moving voice.
  class DissonanceFigures
    attr_reader :notes, :melodic_intervals

    def initialize(notes:, melodic_intervals:, dissonant:)
      @notes = notes
      @melodic_intervals = melodic_intervals
      @dissonant = dissonant
    end

    def passing_tone?(note)
      stepwise_figure?(note, same_direction: true)
    end

    def neighbor_tone?(note)
      stepwise_figure?(note, same_direction: false)
    end

    # Nota cambiata: a five-note figure where note 2 is dissonant,
    # approached by step from note 1, leaps a third in the same direction to
    # note 3, then notes 3-4-5 proceed stepwise in the opposite direction.
    # Notes 1, 3, and 5 must be consonant.
    def cambiata_dissonance?(note)
      start = figure_start(note, 1)
      cambiata_shape?(start) && all_consonant?(*notes.values_at(start, start + 2, start + 4))
    end

    def double_neighbor_member?(note)
      [1, 2].any? { |before| double_neighbor_figure?(figure_start(note, before)) }
    end

    # A passing or neighbor figure of any length: the stepwise run through the
    # note, out to the nearest consonant notes in both directions, moving in
    # one direction (passing) or returning to its starting pitch (neighbor).
    # A rest breaks the run.
    def consonant_run?(note)
      phrase = notes.slice_when { |earlier, later| earlier.next_position < later.position }.detect { |group| group.include?(note) }
      index = phrase.index(note)
      first = phrase.take(index).rindex { |candidate| consonant?(candidate) }
      last = phrase.drop(index + 1).index { |candidate| consonant?(candidate) }
      return false unless first && last

      stepwise_run?(phrase[first..(index + 1 + last)])
    end

    private

    def stepwise_run?(run)
      intervals = run.each_cons(2).map { |pair| HeadMusic::Analysis::MelodicInterval.new(*pair) }
      intervals.all?(&:step?) && (intervals.map(&:direction).uniq.one? || run.first.pitch == run.last.pitch)
    end

    def consonant?(note)
      !@dissonant.call(note)
    end

    def stepwise_figure?(note, same_direction:)
      approach, departure = figure_intervals(figure_start(note, 1), 2)
      return false unless approach

      approach.step? && departure.step? && (approach.direction == departure.direction) == same_direction
    end

    def cambiata_shape?(start)
      approach, leap, *steps_back = figure_intervals(start, 4)
      return false unless approach&.step? && leap.number == 3

      leap_direction = leap.direction
      approach.direction == leap_direction &&
        steps_back.all? { |step| step.step? && step.direction != leap_direction }
    end

    # Double neighbor: a four-note figure. The first and last notes are the
    # same pitch and consonant; the middle two are upper and lower neighbors
    # connected by a leap of a third.
    def double_neighbor_figure?(start)
      first_step, leap, last_step = figure_intervals(start, 3)
      return false unless first_step&.step? && leap.number == 3 && last_step.step?

      opening, closing = notes.values_at(start, start + 3)
      opening.pitch == closing.pitch && all_consonant?(opening, closing)
    end

    # The index of the note +before+ notes ahead of +note+, nil where that
    # runs off the start of the line.
    def figure_start(note, before)
      index = notes.index(note)
      index - before if index && index >= before
    end

    # The melodic intervals of a figure beginning at note +start+, or none
    # where the figure would run off either end of the line.
    def figure_intervals(start, count)
      return [] unless start

      intervals = melodic_intervals[start, count]
      (intervals.length == count) ? intervals : []
    end

    def all_consonant?(*checked_notes)
      checked_notes.none? { |note| @dissonant.call(note) }
    end
  end
end
