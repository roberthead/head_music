# frozen_string_literal: true

# An AugmentedTriad is a sonority containing P1, M3, A5.
class HeadMusic::Analysis::AugmentedTriad < HeadMusic::Analysis::Triad
  def self.diatonic_interval_shorthand
    %w[M3 A5]
  end
end
