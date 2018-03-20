# frozen_string_literal: true

# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::SingleLargeLeaps < HeadMusic::Style::Guidelines::RecoverLargeLeaps
  MESSAGE = 'Recover leaps by step, repetition, opposite direction, or spelling triad.'

  private

  def unrecovered_leap?(first_interval, second_interval, third_interval)
    return false unless first_interval.large_leap?
    return false if spelling_consonant_triad?(first_interval, second_interval, third_interval)
    return false if second_interval.step?
    return false if second_interval.repetition?
    !direction_changed?(first_interval, second_interval) && second_interval.leap?
  end
end
