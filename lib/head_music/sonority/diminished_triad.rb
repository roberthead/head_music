# frozen_string_literal: true

class HeadMusic::Sonority; end

# A MinorTriad is a sonority containing P1, m3, P5.
class HeadMusic::Sonority::DiminishedTriad < HeadMusic::Sonority
  def diatonic_intervals_above_bass_pitch
    %w[m3 d5].map { |shorthand| HeadMusic::DiatonicInterval.get(shorthand) }
  end

  def triad?
    true
  end

  def tertian?
    true
  end
end
