# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Validates that counterpoint notes use only permitted rhythmic values for fifth species.
# Whole notes (final bar only), half notes, quarter notes, and paired stepwise eighth notes
# on weak beats are allowed. No dotted rhythms.
class HeadMusic::Style::Guidelines::AllowedRhythmicValuesForFifthSpecies < HeadMusic::Style::Annotation
  MESSAGE = "Use only permitted rhythmic values: whole (final bar only), half, quarter, " \
    "or paired stepwise eighth notes on weak beats."

  PERMITTED_UNIT_NAMES = %w[whole half quarter eighth].freeze

  def marks
    [
      *disallowed_unit_marks,
      *dotted_rhythm_marks,
      *whole_note_not_in_final_bar_marks,
      *unpaired_eighth_note_marks,
      *non_stepwise_eighth_note_marks,
      *excess_eighth_note_pair_marks
    ]
  end

  private

  def disallowed_unit_marks
    mark_each(notes.reject { |note| PERMITTED_UNIT_NAMES.include?(note.rhythmic_value.unit_name) })
  end

  def dotted_rhythm_marks
    mark_each(notes.select { |note| note.rhythmic_value.dots > 0 })
  end

  def whole_note_not_in_final_bar_marks
    mark_each(
      notes
        .select { |note| note.rhythmic_value.unit_name == "whole" }
        .reject { |note| note.position.bar_number == final_bar_number }
    )
  end

  def unpaired_eighth_note_marks
    mark_each(eighth_notes.reject { |note| paired_eighth?(note) })
  end

  def non_stepwise_eighth_note_marks
    mark_each(
      eighth_notes
        .select { |note| paired_eighth?(note) }
        .reject { |note| stepwise_eighth?(note) }
    )
  end

  def excess_eighth_note_pair_marks
    bars_with_excess_eighth_pairs.flat_map do |bar_number|
      mark_each(eighth_notes_in_bar(bar_number)[2..])
    end
  end

  def mark_each(violating_notes)
    violating_notes.map { |note| HeadMusic::Style::Mark.for(note) }
  end

  def eighth_notes
    @eighth_notes ||= notes.select { |note| note.rhythmic_value.unit_name == "eighth" }
  end

  def paired_eighth?(note)
    prev = preceding_note(note)
    foll = following_note(note)
    (prev && prev.rhythmic_value.unit_name == "eighth") ||
      (foll && foll.rhythmic_value.unit_name == "eighth")
  end

  def stepwise_eighth?(note)
    prev = preceding_note(note)
    foll = following_note(note)
    stepwise_from_prev = prev && HeadMusic::Analysis::MelodicInterval.new(prev, note).step?
    stepwise_to_foll = foll && HeadMusic::Analysis::MelodicInterval.new(note, foll).step?
    stepwise_from_prev || stepwise_to_foll
  end

  def bars_with_excess_eighth_pairs
    eighth_notes
      .group_by { |note| note.position.bar_number }
      .select { |_bar, bar_eighths| bar_eighths.length > 2 }
      .keys
  end

  def eighth_notes_in_bar(bar_number)
    eighth_notes.select { |note| note.position.bar_number == bar_number }
  end

  def final_bar_number
    last_note&.position&.bar_number
  end
end
