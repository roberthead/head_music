# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Unified dissonance handling for mixed-species (florid) contexts.
# - Strong beat dissonances must be properly prepared suspensions from a tie.
# - Weak beat dissonances must be passing tones, neighbor tones, nota cambiata, or double neighbor figures.
# - Tied notes dissonant at the new CF note must resolve by step to a consonance.
class HeadMusic::Style::Guidelines::FloridDissonanceTreatment < HeadMusic::Style::Annotation
  include HeadMusic::Style::Guidelines::DissonanceFigureDetection

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

  def preceding_note(note)
    index = notes.index(note)
    notes[index - 1] if index && index > 0
  end

  def following_note(note)
    index = notes.index(note)
    notes[index + 1] if index && index < notes.length - 1
  end
end
