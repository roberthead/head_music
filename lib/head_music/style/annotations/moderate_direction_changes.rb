# frozen_string_literal: true

module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::ModerateDirectionChanges < HeadMusic::Style::Annotations::DirectionChanges
  MESSAGE = 'Change melodic direction occasionally.'

  def self.maximum_notes_per_direction
    5
  end
end
