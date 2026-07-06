# A free diatonic melody with a valley contour (interior nadir).
class HeadMusic::Style::Guides::ValleyContourMelody < HeadMusic::Style::Guides::DiatonicMelody
  RULESET = contour_ruleset(:valley, minimum_melodic_intervals: 2)
end
