# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A melodic line should change direction often enough. Configurable via the
# `maximum_notes_per_direction:` option; subclasses may set a
# MAXIMUM_NOTES_PER_DIRECTION default and their own MESSAGE.
class HeadMusic::Style::Guidelines::DirectionChanges < HeadMusic::Style::Annotation
  MESSAGE = "Change melodic direction regularly."

  def marks
    return unless overage.positive?

    penalty_exponent = overage**0.5
    HeadMusic::Style::Mark.for_all(notes, fitness: HeadMusic::PENALTY_FACTOR**penalty_exponent)
  end

  private

  def overage
    return 0 if notes.length < 2

    [notes_per_direction - maximum_notes_per_direction, 0].max
  end

  def maximum_notes_per_direction
    options.fetch(:maximum_notes_per_direction) { self.class::MAXIMUM_NOTES_PER_DIRECTION }
  end

  def notes_per_direction
    notes.length.to_f / (melodic_intervals_changing_direction.length + 1)
  end

  def melodic_intervals_changing_direction
    melodic_intervals.each_cons(2).reject do |interval_pair|
      interval_pair[0].direction == interval_pair[1].direction
    end
  end
end
