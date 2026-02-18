# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Base class for guidelines requiring a step in a specific direction to the final note.
class HeadMusic::Style::Guidelines::DirectionalStepToFinalNote < HeadMusic::Style::Annotation
  def marks
    return if last_melodic_interval.nil?

    fitness = 1
    fitness *= HeadMusic::PENALTY_FACTOR unless step?
    fitness *= HeadMusic::PENALTY_FACTOR unless expected_direction?
    HeadMusic::Style::Mark.for_all(notes[-2..], fitness: fitness) if fitness < 1
  end

  private

  def expected_direction?
    raise NotImplementedError
  end

  def step?
    last_melodic_interval&.step?
  end

  def last_melodic_interval
    @last_melodic_interval ||= melodic_intervals.last
  end
end
