# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Shared detection of ornamental dissonance figures (nota cambiata, double neighbor)
# plus the melodic helpers those figures and their surrounding guidelines rely on.
# Include in any dissonance treatment guideline that recognizes these figures.
# Expects the including class to provide: #notes, #cantus_firmus, #voice.
module HeadMusic::Style::Guidelines::DissonanceFigureDetection
  private

  # A note whose pitch clashes with the cantus firmus in two-part harmony.
  def dissonant_with_cantus?(note)
    interval = HeadMusic::Analysis::HarmonicInterval.new(cantus_firmus, voice, note.position)
    interval.notes.length == 2 && interval.dissonance?(:two_part_harmony)
  end

  # Positions where the cantus firmus sounds a note (the strong beats).
  def cantus_firmus_positions
    @cantus_firmus_positions ||= Set.new(cantus_firmus.notes.map { |note| note.position.to_s })
  end

  def passing_tone?(note)
    stepwise_figure?(note, same_direction: true)
  end

  def neighbor_tone?(note)
    stepwise_figure?(note, same_direction: false)
  end

  def stepwise_figure?(note, same_direction:)
    prev_note = preceding_note(note)
    next_note = following_note(note)
    return false unless prev_note && next_note

    approach = melodic_interval_between(prev_note, note)
    departure = melodic_interval_between(note, next_note)
    approach.step? && departure.step? && (approach.direction == departure.direction) == same_direction
  end

  # Nota cambiata: a five-note figure where note 2 is dissonant,
  # approached by step from note 1, leaps a third in the same direction to note 3,
  # then notes 3-4-5 proceed stepwise in the opposite direction.
  # Notes 1, 3, and 5 must be consonant with the CF.
  def cambiata_dissonance?(note)
    index = notes.index(note)
    return false unless index

    cambiata_as_note_2?(index)
  end

  def double_neighbor_member?(note)
    index = notes.index(note)
    return false unless index

    double_neighbor_figure?(index, offset: 1) || double_neighbor_figure?(index, offset: 2)
  end

  def cambiata_as_note_2?(index)
    return false if index < 1 || index + 3 > notes.length - 1

    n1, n2, n3, n4, n5 = notes[index - 1, 5]

    approach = melodic_interval_between(n1, n2)
    leap = melodic_interval_between(n2, n3)
    step_back_1 = melodic_interval_between(n3, n4)
    step_back_2 = melodic_interval_between(n4, n5)

    approach.step? &&
      leap.number == 3 && approach.direction == leap.direction &&
      step_back_1.step? && step_back_2.step? &&
      step_back_1.direction != leap.direction &&
      step_back_2.direction != leap.direction &&
      consonant_with_cantus?(n1) && consonant_with_cantus?(n3) && consonant_with_cantus?(n5)
  end

  # Double neighbor: a four-note figure within one bar.
  # Beats 1 and 4 are the same pitch (consonant), beats 2 and 3 are
  # upper and lower neighbors connected by a leap of a third.
  def double_neighbor_figure?(index, offset:)
    start = index - offset
    return false if start < 0 || start + 3 > notes.length - 1

    n1, n2, n3, n4 = notes[start, 4]

    approach = melodic_interval_between(n1, n2)
    middle = melodic_interval_between(n2, n3)
    departure = melodic_interval_between(n3, n4)

    approach.step? && middle.number == 3 && departure.step? &&
      n1.pitch == n4.pitch &&
      consonant_with_cantus?(n1) && consonant_with_cantus?(n4)
  end

  def consonant_with_cantus?(note)
    !dissonant_with_cantus?(note)
  end

  def melodic_interval_between(note1, note2)
    HeadMusic::Analysis::MelodicInterval.new(note1, note2)
  end
end
