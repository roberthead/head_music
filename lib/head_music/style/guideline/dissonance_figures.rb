module HeadMusic::Style; end

class HeadMusic::Style::Guideline
  # The ornamental figures a dissonant note can belong to in one line: passing
  # tone, neighbor tone, nota cambiata, double neighbor, and escape tone. The
  # line is given as its notes and melodic intervals; the dissonance test is
  # given as a callable, so the same figures can be read in a voice moving
  # against a cantus firmus or against another moving voice.
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
      cambiata_figure?(figure_start(note, 1))
    end

    def double_neighbor_member?(note)
      [1, 2].any? { |before| double_neighbor_figure?(figure_start(note, before)) }
    end

    # The four notes of each completed double neighbor. Where both neighbors
    # are consonant the shape excuses nothing and is only a turn in the line.
    def double_neighbors
      @double_neighbors ||= notes.each_index
        .select { |start| double_neighbor_figure?(start) }
        .map { |start| notes[start, 4] }
        .reject { |figure| all_consonant?(*figure) }
    end

    def double_neighbors_with(note)
      double_neighbors.select { |figure| figure[1, 2].include?(note) }
    end

    # The five notes of each cambiata. With a consonant second note the shape
    # excuses nothing.
    def cambiatas
      @cambiatas ||= notes.each_index
        .select { |start| cambiata_figure?(start) && dissonant?(notes[start + 1]) }
        .map { |start| notes[start, 5] }
    end

    def dissonant?(note)
      @dissonant.call(note)
    end

    def dissonant_among(figure)
      figure.select { |note| dissonant?(note) }
    end

    # Escape tone: approached by step from a consonant note and left by a
    # third in the opposite direction to a consonant note. The first neighbor
    # of a double neighbor has the same shape and belongs to that figure.
    def escape_tone?(note)
      start = figure_start(note, 1)
      escape_shape?(start) &&
        all_consonant?(*notes.values_at(start, start + 2)) &&
        !double_neighbor_figure?(start)
    end

    # A passing or neighbor figure of any length, read as a ConsonantRun.
    def consonant_run?(note)
      run = run_through(note)
      run.passing? || run.returning?
    end

    # The passing half of a consonant run, which is all a dissonant half note
    # may be.
    def passing_run?(note)
      run_through(note).passing?
    end

    private

    def run_through(note)
      HeadMusic::Style::Guideline::ConsonantRun.new(line: notes, note: note, dissonant: @dissonant)
    end

    def consonant?(note)
      !dissonant?(note)
    end

    def cambiata_figure?(start)
      cambiata_shape?(start) && all_consonant?(*notes.values_at(start, start + 2, start + 4))
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

    def escape_shape?(start)
      approach, leap = figure_intervals(start, 2)
      return false unless approach&.step? && leap.number == 3

      approach.direction != leap.direction
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
      checked_notes.none? { |note| dissonant?(note) }
    end
  end
end
