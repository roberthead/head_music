# frozen_string_literal: true

module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::StepDownToFinalNote < HeadMusic::Style::Annotation
  MESSAGE = 'Step down to the final note.'

  def marks
    unless last_melodic_interval.nil?
      fitness = 1
      fitness *= HeadMusic::PENALTY_FACTOR unless step?
      fitness *= HeadMusic::PENALTY_FACTOR unless descending?
      HeadMusic::Style::Mark.for_all(notes[-2..-1], fitness: fitness) if fitness < 1
    end
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
