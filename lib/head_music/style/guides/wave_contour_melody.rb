# A free diatonic melody with a wave contour (repeated undulation at the trend level).
class HeadMusic::Style::Guides::WaveContourMelody < HeadMusic::Style::Guides::DiatonicMelody
  RULESET = contour_ruleset(:wave, minimum_melodic_intervals: 2)
end
