# frozen_string_literal: true

# A MinorTriad is a sonority containing P1, m3, P5.
class HeadMusic::Analysis::MinorTriad < HeadMusic::Analysis::Triad
  def diatonic_intervals_above_bass_pitch
    %w[m3 P5].map { |shorthand| HeadMusic::DiatonicInterval.get(shorthand) }
  end
end
