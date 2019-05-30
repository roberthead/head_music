# frozen_string_literal: true

class HeadMusic::Sonority; end

# A MajorTriad is a sonority containing P1, M3, P5.
class HeadMusic::Sonority::MajorTriad < HeadMusic::Sonority
  def diatonic_intervals_above_bass_pitch
    %w[M3 P5].map { |shorthand| HeadMusic::DiatonicInterval.get(shorthand) }
  end

  def triad?
    true
  end

  def consonant_triad?
    true
  end

  def tertian?
    true
  end
end
