# A module for music rudiments
module HeadMusic::Rudiment; end

# Just Intonation tuning system based on whole number frequency ratios
class HeadMusic::Rudiment::Tuning::JustIntonation < HeadMusic::Rudiment::Tuning
  include HeadMusic::Rudiment::Tuning::TonalCentered

  # Frequency ratios for intervals in just intonation (relative to tonic)
  # Based on the major scale with pure intervals
  INTERVAL_RATIOS = {
    unison: Rational(1, 1),
    minor_second: Rational(16, 15),
    major_second: Rational(9, 8),
    minor_third: Rational(6, 5),
    major_third: Rational(5, 4),
    perfect_fourth: Rational(4, 3),
    tritone: Rational(45, 32),
    perfect_fifth: Rational(3, 2),
    minor_sixth: Rational(8, 5),
    major_sixth: Rational(5, 3),
    minor_seventh: Rational(16, 9),
    major_seventh: Rational(15, 8),
    octave: Rational(2, 1)
  }.freeze
end
