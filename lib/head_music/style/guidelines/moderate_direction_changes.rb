# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::ModerateDirectionChanges < HeadMusic::Style::Guidelines::DirectionChanges
  MESSAGE = "Change melodic direction occasionally."
  MAXIMUM_NOTES_PER_DIRECTION = 5
end
