# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::StepDownToFinalNote < HeadMusic::Style::Guidelines::DirectionalStepToFinalNote
  MESSAGE = "Step down to the final note."

  private

  def expected_direction?
    last_melodic_interval&.descending?
  end
end
