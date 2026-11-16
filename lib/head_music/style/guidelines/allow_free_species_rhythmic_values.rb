# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Fifth species note values for free species, where a whole note may fall in
# any bar. With `dotted_rhythms: true`, a dotted half or dotted whole is
# allowed, as the same rhythm written with a tie would be, and so is a dotted
# quarter followed by a single eighth that steps to the next note. That
# eighth still counts toward the bar's eighth notes.
class HeadMusic::Style::Guidelines::AllowFreeSpeciesRhythmicValues < HeadMusic::Style::Guidelines::AllowFifthSpeciesRhythmicValues
  TIE_EQUIVALENT_DOTTED_UNIT_NAMES = %w[half whole].freeze

  DOTTED_VIOLATION_KEY = "guidelines.allow_free_species_rhythmic_values.violations.with_dotted_rhythms"

  def self.violation_key(config = {})
    config[:dotted_rhythms] ? DOTTED_VIOLATION_KEY : super
  end

  # Both, whichever the configuration names, so load-time verification renders
  # the dotted sentence though the registry holds only the plain guide.
  def self.violation_keys(config = {})
    [*super({}), DOTTED_VIOLATION_KEY]
  end

  def self.render_instruction(config)
    return super unless config[:dotted_rhythms]

    render_template("guidelines.#{template_key}.instruction_with_dotted_rhythms", config)
  end

  private

  def dotted_rhythms?
    options.fetch(:dotted_rhythms, false)
  end

  def whole_note_not_in_final_bar_marks
    []
  end

  def dotted_rhythm_marks
    return super unless dotted_rhythms?

    mark_each(notes.select { |note| dotted?(note) && !permitted_dot?(note) })
  end

  def unpaired_eighth_note_marks
    return super unless dotted_rhythms?

    mark_each(eighth_notes.reject { |note| paired_eighth?(note) || eighth_after_dotted_quarter?(note) })
  end

  def dotted?(note)
    note.rhythmic_duration.values.any? { |value| value.dots > 0 }
  end

  def permitted_dot?(note)
    values = note.rhythmic_duration.values
    values.all? { |value| value.dots.zero? || single_dot?(value, TIE_EQUIVALENT_DOTTED_UNIT_NAMES) } ||
      (values.length == 1 && single_dot?(values.first, %w[quarter]) && stepping_eighth_follows?(note))
  end

  def single_dot?(value, unit_names)
    value.dots == 1 && unit_names.include?(value.unit_name)
  end

  def stepping_eighth_follows?(note)
    eighth = following_note(note)
    eighth && attack_unit_name(eighth) == "eighth" && !paired_eighth?(eighth) && steps_onward?(eighth)
  end

  def eighth_after_dotted_quarter?(note)
    previous = preceding_note(note)
    previous && permitted_dot?(previous) && single_dot?(previous.rhythmic_duration.values.first, %w[quarter])
  end

  def steps_onward?(note)
    onward = following_note(note)
    onward && HeadMusic::Analysis::MelodicInterval.new(note, onward).step?
  end
end
