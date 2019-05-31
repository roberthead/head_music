# frozen_string_literal: true

# A Triad is a sonority containing a third and a fifth above the root.
class HeadMusic::Analysis::Triad < HeadMusic::Analysis::Sonority
  SCALE_DEGREES_ABOVE_BASS_PITCH = [3, 5].freeze

  def tertian?
    true
  end
end
