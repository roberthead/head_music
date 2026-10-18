# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Shared detection of ornamental dissonance figures (nota cambiata, double
# neighbor). Expects the including class to provide #notes, #melodic_intervals,
# and #dissonant_with_cantus_at?, as every Guideline does.
module HeadMusic::Style::Guidelines::DissonanceFigureDetection
  private

  def dissonant_with_cantus?(note)
    dissonant_with_cantus_at?(note.position)
  end

  def passing_tone?(note)
    stepwise_figure?(note, same_direction: true)
  end

  def neighbor_tone?(note)
    stepwise_figure?(note, same_direction: false)
  end

  def stepwise_figure?(note, same_direction:)
    approach, departure = figure_intervals(figure_start(note, 1), 2)
    return false unless approach

    approach.step? && departure.step? && (approach.direction == departure.direction) == same_direction
  end

  # Nota cambiata: a five-note figure where note 2 is dissonant,
  # approached by step from note 1, leaps a third in the same direction to note 3,
  # then notes 3-4-5 proceed stepwise in the opposite direction.
  # Notes 1, 3, and 5 must be consonant with the CF.
  def cambiata_dissonance?(note)
    start = figure_start(note, 1)
    cambiata_shape?(start) &&
      all_consonant_with_cantus?(*notes.values_at(start, start + 2, start + 4))
  end

  def cambiata_shape?(start)
    approach, leap, *steps_back = figure_intervals(start, 4)
    return false unless approach&.step? && leap.number == 3

    leap_direction = leap.direction
    approach.direction == leap_direction &&
      steps_back.all? { |step| step.step? && step.direction != leap_direction }
  end

  def double_neighbor_member?(note)
    [1, 2].any? { |before| double_neighbor_figure?(figure_start(note, before)) }
  end

  # Double neighbor: a four-note figure within one bar.
  # Beats 1 and 4 are the same pitch (consonant), beats 2 and 3 are
  # upper and lower neighbors connected by a leap of a third.
  def double_neighbor_figure?(start)
    first_step, leap, last_step = figure_intervals(start, 3)
    return false unless first_step&.step? && leap.number == 3 && last_step.step?

    opening, closing = notes.values_at(start, start + 3)
    opening.pitch == closing.pitch && all_consonant_with_cantus?(opening, closing)
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

  def all_consonant_with_cantus?(*checked_notes)
    checked_notes.none? { |note| dissonant_with_cantus?(note) }
  end
end
