# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Unified dissonance handling for mixed-species (florid) contexts.
# - Strong beat dissonances must be properly prepared suspensions from a tie.
# - Weak beat dissonances must be passing tones, neighbor tones, nota cambiata, or double neighbor figures.
# - Tied notes dissonant at the new CF note must resolve by step to a consonance.
class HeadMusic::Style::Guidelines::FloridDissonanceTreatment < HeadMusic::Style::Annotation
  MESSAGE = "Treat dissonances appropriately: passing tones, cambiata, or double neighbor " \
    "on weak beats; proper suspension treatment for tied notes."

  def marks
    return [] unless cantus_firmus&.notes&.any?

    improperly_treated_notes.map { |note| HeadMusic::Style::Mark.for(note) }
  end

  private

  def improperly_treated_notes
    notes.select { |note| dissonant_with_cantus?(note) && !properly_treated?(note) }
  end

  def properly_treated?(note)
    if on_strong_beat?(note)
      properly_treated_suspension?(note)
    else
      passing_tone?(note) || neighbor_tone?(note) ||
        cambiata_dissonance?(note) || double_neighbor_member?(note)
    end
  end

  # A note on a strong beat that is dissonant must be a tied suspension
  # (its position is before the CF note position, meaning it was held over).
  def properly_treated_suspension?(note)
    cf_note = current_cf_note_at(note.position)
    return false unless cf_note

    # The CP note must have started before the CF note (tied over)
    note.position < cf_note.position && resolved_by_step?(note)
  end

  def resolved_by_step?(note)
    next_cp = following_note(note)
    return false unless next_cp

    melodic = melodic_interval_between(note, next_cp)
    return false unless melodic.step?

    # Resolution must be consonant
    consonant_with_cantus?(next_cp)
  end

  def on_strong_beat?(note)
    cantus_firmus_positions.include?(note.position.to_s)
  end

  def cantus_firmus_positions
    @cantus_firmus_positions ||= Set.new(cantus_firmus.notes.map { |note| note.position.to_s })
  end

  def current_cf_note_at(position)
    cantus_firmus.note_at(position)
  end

  def dissonant_with_cantus?(note)
    interval = HeadMusic::Analysis::HarmonicInterval.new(cantus_firmus, voice, note.position)
    interval.notes.length == 2 && interval.dissonance?(:two_part_harmony)
  end

  def consonant_with_cantus?(note)
    !dissonant_with_cantus?(note)
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
