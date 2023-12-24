# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::ModerateDirectionChanges < HeadMusic::Style::Guidelines::DirectionChanges
  MESSAGE = "Change melodic direction occasionally."

  def self.maximum_notes_per_direction
    5
  end
end
