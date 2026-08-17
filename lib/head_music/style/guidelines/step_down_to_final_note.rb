# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::StepDownToFinalNote < HeadMusic::Style::Guidelines::DirectionalStepToFinalNote
  private

  def expected_direction?
    last_melodic_interval&.descending?
  end
end
