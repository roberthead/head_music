# frozen_string_literal: true

# Module for Annotations.
module HeadMusic::Style::Annotations; end

# A counterpoint guideline
class HeadMusic::Style::Annotations::FrequentDirectionChanges < HeadMusic::Style::Annotations::DirectionChanges
  MESSAGE = 'Change melodic direction frequently.'

  def self.maximum_notes_per_direction
    3
  end
end
