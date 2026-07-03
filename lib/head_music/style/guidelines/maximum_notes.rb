# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a melody with more than the allowed number of notes.
# Configurable via the `maximum:` option; subclasses may set a MAXIMUM_NOTES default.
class HeadMusic::Style::Guidelines::MaximumNotes < HeadMusic::Style::Annotation
  def marks
    HeadMusic::Style::Mark.for_each(notes[maximum..]) if overage.positive?
  end

  def message
    "Write up to #{maximum.humanize} notes."
  end

  private

  def maximum
    options.fetch(:maximum) { self.class::MAXIMUM_NOTES }
  end

  def overage
    [notes.length - maximum, 0].max
  end
end
