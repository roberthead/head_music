# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a melody with fewer than the required number of notes.
# Configure the threshold with the factory, e.g. MinimumNotes.with(8).
class HeadMusic::Style::Guidelines::MinimumNotes < HeadMusic::Style::Annotation
  def self.with(minimum)
    super(minimum: minimum)
  end

  def self.default_gate?
    true
  end

  def marks
    placements.empty? ? no_placements_mark : deficiency_mark
  end

  def message
    "Write at least #{minimum.humanize} notes."
  end

  private

  def minimum
    options.fetch(:minimum)
  end

  def no_placements_mark
    HeadMusic::Style::Mark.new(
      HeadMusic::Content::Position.new(composition, "1:1"),
      HeadMusic::Content::Position.new(composition, "2:1"),
      fitness: 0
    )
  end

  def deficiency_mark
    return unless notes.length < minimum

    HeadMusic::Style::Mark.for_all(placements, fitness: notes.length.to_f / minimum)
  end
end
