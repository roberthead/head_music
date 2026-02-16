# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline for third-species dissonance treatment.
# Every dissonant note on beats 2, 3, or 4 must be treated as a passing tone,
# neighbor tone, nota cambiata, or double neighbor figure.
class HeadMusic::Style::Guidelines::ThirdSpeciesDissonanceTreatment < HeadMusic::Style::Annotation
  MESSAGE = "Treat dissonances as passing tones, neighbor tones, cambiata, or double neighbor figures."

  def marks
    return [] unless cantus_firmus&.notes&.any?

    unresolved_dissonant_notes.map { |note| HeadMusic::Style::Mark.for(note) }
  end

  private

  def unresolved_dissonant_notes
    dissonant_weak_beat_notes.reject { |note| recognized_figure?(note) }
  end

  def recognized_figure?(note)
    passing_tone?(note) || neighbor_tone?(note) || cambiata_dissonance?(note) || double_neighbor_member?(note)
  end

  # Passing tone: approached by step and left by step in the same direction.
  def passing_tone?(note)
    prev = preceding_note(note)
    foll = following_note(note)
    return false unless prev && foll

    approach = melodic_interval_between(prev, note)
    departure = melodic_interval_between(note, foll)

    approach.step? && departure.step? && approach.direction == departure.direction
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

    double_neighbor_as_note_2?(index) || double_neighbor_as_note_3?(index)
  end

  def double_neighbor_as_note_2?(index)
    return false if index < 1 || index + 2 > notes.length - 1

    n1 = notes[index - 1]
    n2 = notes[index]
    n3 = notes[index + 1]
    n4 = notes[index + 2]

    approach = melodic_interval_between(n1, n2)
    middle = melodic_interval_between(n2, n3)
    departure = melodic_interval_between(n3, n4)

    approach.step? && middle.number == 3 && departure.step? &&
      n1.pitch == n4.pitch &&
      consonant_with_cantus?(n1) && consonant_with_cantus?(n4)
  end

  def double_neighbor_as_note_3?(index)
    return false if index < 2 || index + 1 > notes.length - 1

    n1 = notes[index - 2]
    n2 = notes[index - 1]
    n3 = notes[index]
    n4 = notes[index + 1]

    approach = melodic_interval_between(n1, n2)
    middle = melodic_interval_between(n2, n3)
    departure = melodic_interval_between(n3, n4)

    approach.step? && middle.number == 3 && departure.step? &&
      n1.pitch == n4.pitch &&
      consonant_with_cantus?(n1) && consonant_with_cantus?(n4)
  end

  def dissonant_weak_beat_notes
    weak_beat_notes.select { |note| dissonant_with_cantus?(note) }
  end

  def weak_beat_notes
    notes.reject { |note| downbeat_position?(note.position) }
  end

  def downbeat_position?(position)
    cantus_firmus_positions.include?(position.to_s)
  end

  def cantus_firmus_positions
    @cantus_firmus_positions ||= Set.new(cantus_firmus.notes.map { |n| n.position.to_s })
  end

  def dissonant_with_cantus?(note)
    interval = HeadMusic::Analysis::HarmonicInterval.new(cantus_firmus, voice, note.position)
    interval.notes.length == 2 && interval.dissonance?(:two_part_harmony)
  end

  def consonant_with_cantus?(note)
    !dissonant_with_cantus?(note)
  end

  def melodic_interval_between(note1, note2)
    HeadMusic::Analysis::MelodicInterval.new(note1, note2)
  end

  def preceding_note(note)
    index = notes.index(note)
    notes[index - 1] if index && index > 0
  end

  def following_note(note)
    index = notes.index(note)
    notes[index + 1] if index && index < notes.length - 1
  end
end
