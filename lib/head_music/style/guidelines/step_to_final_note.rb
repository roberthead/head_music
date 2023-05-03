# frozen_string_literal: true

# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::StepToFinalNote < HeadMusic::Style::Annotation
  MESSAGE = "Step to the final note."

  def marks
    HeadMusic::Style::Mark.for_all(notes[-2..]) unless step_to_final_note?
  end

  private

  def step_to_final_note?
    last_melodic_interval&.step?
  end

  def last_melodic_interval
    @last_melodic_interval ||= melodic_intervals.last
  end
end
