# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::ModerateDirectionChanges < HeadMusic::Style::Guidelines::DirectionChanges
  # Declared here rather than on DirectionChanges, because strength is never
  # inherited -- see Guideline::Strength.
  strength :weak, because: "a long run in one direction is a shapeliness judgment, and the threshold is a rule of thumb"

  MAXIMUM_NOTES_PER_DIRECTION = 5
end
