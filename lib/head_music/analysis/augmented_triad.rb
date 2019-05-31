# frozen_string_literal: true

# An AugmentedTriad is a sonority containing P1, M3, A5.
class HeadMusic::Analysis::AugmentedTriad < HeadMusic::Analysis::Triad
  def diatonic_intervals_above_bass_pitch
    %w[M3 A5].map { |shorthand| HeadMusic::DiatonicInterval.get(shorthand) }
  end
end
