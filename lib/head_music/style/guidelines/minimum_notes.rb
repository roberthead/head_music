# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a melody with fewer than the required number of notes.
# Configure the threshold with the factory, e.g. MinimumNotes.with(8).
class HeadMusic::Style::Guidelines::MinimumNotes < HeadMusic::Style::Guidelines::MinimumThreshold
  def marks
    placements.empty? ? no_placements_mark : deficiency_mark
  end

  # The count comes from the configuration or the class default -- never from
  # config alone, which is empty for the unconfigured case.
  def self.template_values(config)
    count = config.fetch(:minimum) { MINIMUM }
    {count: count, number: HeadMusic::Style::Template.number_word(count)}
  end

  private

  def actual_count
    notes.length
  end
end
