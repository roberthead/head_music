# frozen_string_literal: true

# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::StepDownToFinalNote < HeadMusic::Style::Annotation
  MESSAGE = "Step down to the final note."

  def marks
    return if last_melodic_interval.nil?

    fitness = 1
    fitness *= HeadMusic::PENALTY_FACTOR unless step?
    fitness *= HeadMusic::PENALTY_FACTOR unless descending?
    HeadMusic::Style::Mark.for_all(notes[-2..], fitness: fitness) if fitness < 1
  end

  private

  def descending?
    last_melodic_interval&.descending?
  end

  def step?
    last_melodic_interval&.step?
  end

  def last_melodic_interval
    @last_melodic_interval ||= melodic_intervals.last
  end
end
