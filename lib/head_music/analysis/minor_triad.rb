# frozen_string_literal: true

# A MinorTriad is a sonority containing P1, m3, P5.
class HeadMusic::Analysis::MinorTriad < HeadMusic::Analysis::Triad
  def self.diatonic_interval_shorthand
    %w[m3 P5]
  end
end
