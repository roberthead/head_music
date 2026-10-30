# A module for music rudiments
module HeadMusic::Rudiment; end

# Compares rhythmic units, values, and durations by how long they last, apart
# from equality, which compares how they are written: a dotted half lasts as
# long as a half tied to a quarter, though the two are not ==.
module HeadMusic::Rudiment::DurationComparison
  include Comparable

  def <=>(other)
    fraction <=> other.fraction if other.is_a?(HeadMusic::Rudiment::DurationComparison)
  end

  def same_duration_as?(other)
    other = HeadMusic::Rudiment::RhythmicDuration.get(other) if other.is_a?(String) || other.is_a?(Symbol)
    other.is_a?(HeadMusic::Rudiment::DurationComparison) && fraction == other.fraction
  end
end
