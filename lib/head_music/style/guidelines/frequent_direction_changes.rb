# frozen_string_literal: true

# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::FrequentDirectionChanges < HeadMusic::Style::Guidelines::DirectionChanges
  MESSAGE = "Change melodic direction frequently."

  def self.maximum_notes_per_direction
    3
  end
end
