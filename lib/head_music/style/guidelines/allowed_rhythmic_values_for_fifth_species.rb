# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# All rhythmic values are allowed in fifth species counterpoint.
# This guideline is always adherent.
class HeadMusic::Style::Guidelines::AllowedRhythmicValuesForFifthSpecies < HeadMusic::Style::Annotation
  MESSAGE = "All rhythmic values are allowed in fifth species."

  def marks
    []
  end
end
