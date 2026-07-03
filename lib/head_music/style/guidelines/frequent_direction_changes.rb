# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::FrequentDirectionChanges < HeadMusic::Style::Guidelines::DirectionChanges
  MESSAGE = "Change melodic direction frequently."
  MAXIMUM_NOTES_PER_DIRECTION = 3
end
