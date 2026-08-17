# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a melody with more than the allowed number of notes.
# Configure the threshold with the factory, e.g. MaximumNotes.with(14).
class HeadMusic::Style::Guidelines::MaximumNotes < HeadMusic::Style::Guideline
  def self.with(maximum, **options)
    super(maximum: maximum, **options)
  end

  def marks
    HeadMusic::Style::Mark.for_each(notes[maximum..]) if overage.positive?
  end

  def self.violation_singular = "note"

  # The count comes from the configuration or the class default -- never from
  # config alone, which is empty for the unconfigured case.
  def self.template_values(config)
    count = config.fetch(:maximum)
    {count: count, number: HeadMusic::Style::Template.number_word(count)}
  end

  protected

  # Score by the rate of overage notes rather than the raw count,
  # so fitness is invariant to melody length.
  def fitness_denominator
    notes.length
  end

  private

  def maximum
    options.fetch(:maximum)
  end

  def overage
    [notes.length - maximum, 0].max
  end
end
