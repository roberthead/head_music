# Modern/standard practice tradition for interval consonance classification
class HeadMusic::Style::ModernTradition < HeadMusic::Style::Tradition
  def consonance_classification(interval)
    interval_mod = interval.simple_semitones

    # Check for augmented or diminished intervals (except diminished fifth/augmented fourth)
    if (interval.augmented? || interval.diminished?) && interval_mod != 6
      return HeadMusic::Rudiment::Consonance::DISSONANCE
    end

    case interval_mod
    when 0, 12  # Unison, Octave
      HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE
    when 7      # Perfect Fifth
      HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE
    when 3, 4   # Minor Third, Major Third
      HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE
    when 8, 9   # Minor Sixth, Major Sixth
      HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE
    when 5      # Perfect Fourth
      # In standard practice, perfect fourth is considered consonant
      # but contextual would be more accurate
      HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE
    when 2, 10  # Major Second, Minor Seventh
      HeadMusic::Rudiment::Consonance::MILD_DISSONANCE
    when 1, 11  # Minor Second, Major Seventh
      HeadMusic::Rudiment::Consonance::HARSH_DISSONANCE
    when 6      # Tritone (Aug 4th/Dim 5th)
      HeadMusic::Rudiment::Consonance::DISSONANCE
    else
      HeadMusic::Rudiment::Consonance::DISSONANCE
    end
  end
end
