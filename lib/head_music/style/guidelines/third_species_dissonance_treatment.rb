# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline for third-species dissonance treatment.
# Every dissonant note on beats 2, 3, or 4 must be treated as a passing tone,
# neighbor tone, nota cambiata, or double neighbor figure.
class HeadMusic::Style::Guidelines::ThirdSpeciesDissonanceTreatment < HeadMusic::Style::Guidelines::WeakBeatDissonanceTreatment
  MESSAGE = "Treat dissonances as passing tones, neighbor tones, cambiata, or double neighbor figures."

  private

  def recognized_figure?(note)
    super || neighbor_tone?(note) || cambiata_dissonance?(note) || double_neighbor_member?(note)
  end

  # Neighbor tone: approached by step, left by step in the opposite direction.
  def neighbor_tone?(note)
    prev = preceding_note(note)
    foll = following_note(note)
    return false unless prev && foll

    approach = melodic_interval_between(prev, note)
    departure = melodic_interval_between(note, foll)

    approach.step? && departure.step? && approach.direction != departure.direction
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

  def cambiata_as_note_2?(index)
    return false if index < 1 || index + 3 > notes.length - 1

    n1 = notes[index - 1]
    n2 = notes[index]
    n3 = notes[index + 1]
    n4 = notes[index + 2]
    n5 = notes[index + 3]

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
  def double_neighbor_member?(note)
    index = notes.index(note)
    return false unless index

    double_neighbor_figure?(index, offset: 1) || double_neighbor_figure?(index, offset: 2)
  end

  # Check for a double-neighbor four-note figure where the given index
  # is note number (offset + 1) in the figure. offset=1 means note 2,
  # offset=2 means note 3.
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
end
