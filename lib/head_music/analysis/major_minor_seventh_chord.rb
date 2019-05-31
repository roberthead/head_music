# frozen_string_literal: true

# A MajorMinorSeventhChord is a sonority containing P1 M3 P5 m7.
class HeadMusic::Analysis::MajorMinorSeventhChord < HeadMusic::Analysis::Sonority
  def self.diatonic_interval_shorthand
    %w[M3 P5 m7]
  end
end
