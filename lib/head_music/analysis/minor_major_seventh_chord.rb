# frozen_string_literal: true

# A MinorMajorSeventhChord is a sonority containing P1 m3 P5 M7.
class HeadMusic::Analysis::MinorMajorSeventhChord < HeadMusic::Analysis::Sonority
  def self.diatonic_interval_shorthand
    %w[m3 P5 M7]
  end
end
