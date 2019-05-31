# frozen_string_literal: true

# A DiminishedTriad is a sonority containing P1, m3, d5.
class HeadMusic::Analysis::DiminishedTriad < HeadMusic::Analysis::Triad
  def diatonic_intervals_above_bass_pitch
    %w[m3 d5].map { |shorthand| HeadMusic::DiatonicInterval.get(shorthand) }
  end
end
