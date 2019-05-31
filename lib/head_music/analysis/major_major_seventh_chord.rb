# frozen_string_literal: true

# A MajorMajorSeventhChord is a sonority containing P1 M3 P5 M7.
class HeadMusic::Analysis::MajorMajorSeventhChord < HeadMusic::Analysis::Sonority
  def self.diatonic_interval_shorthand
    %w[M3 P5 M7]
  end
end
