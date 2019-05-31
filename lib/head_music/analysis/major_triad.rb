# frozen_string_literal: true

# A MajorTriad is a sonority containing P1, M3, P5.
class HeadMusic::Analysis::MajorTriad < HeadMusic::Analysis::Triad
  def diatonic_intervals_above_bass_pitch
    %w[M3 P5].map { |shorthand| HeadMusic::DiatonicInterval.get(shorthand) }
  end
end
