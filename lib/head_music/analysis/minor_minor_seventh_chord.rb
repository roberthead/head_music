# frozen_string_literal: true

# A MinorMinorSeventhChord is a sonority containing P1 m3 P5 m7.
class HeadMusic::Analysis::MinorMinorSeventhChord < HeadMusic::Analysis::Sonority
  def self.diatonic_interval_shorthand
    %w[m3 P5 m7]
  end
end
