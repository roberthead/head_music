# Medieval tradition for interval consonance classification
class HeadMusic::Style::MedievalTradition < HeadMusic::Style::Tradition
  def consonance_classification(interval)
    interval_mod = interval.simple_semitones

    # Check for augmented or diminished intervals
    if interval.augmented? || interval.diminished?
      return HeadMusic::Rudiment::Consonance::DISSONANCE
    end

    case interval_mod
    when 0, 12  # Unison, Octave
      HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE
    when 7      # Perfect Fifth
      HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE
    when 5      # Perfect Fourth - consonant in medieval music
      HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE
    when 3, 4   # Minor Third, Major Third
      HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE
    when 8, 9   # Minor Sixth, Major Sixth
      HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE
    else
      HeadMusic::Rudiment::Consonance::DISSONANCE
    end
  end
end
