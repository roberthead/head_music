# frozen_string_literal: true

# A DiminishedTriad is a sonority containing P1, m3, d5.
class HeadMusic::Analysis::DiminishedTriad < HeadMusic::Analysis::Sonority
  def self.diatonic_interval_shorthand
    %w[m3 d5]
  end
end
