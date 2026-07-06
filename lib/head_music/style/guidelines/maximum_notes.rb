# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a melody with more than the allowed number of notes.
# Configure the threshold with the factory, e.g. MaximumNotes.with(14).
class HeadMusic::Style::Guidelines::MaximumNotes < HeadMusic::Style::Annotation
  def self.with(maximum)
    super(maximum: maximum)
  end

  def marks
    HeadMusic::Style::Mark.for_each(notes[maximum..]) if overage.positive?
  end

  def message
    "Write up to #{maximum.humanize} notes."
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
