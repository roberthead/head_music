# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::ModerateDirectionChanges < HeadMusic::Style::Guidelines::DirectionChanges
  MAXIMUM_NOTES_PER_DIRECTION = 5
end
