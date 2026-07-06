# A free diatonic melody with an ascending contour (departs its floor, arrives at its ceiling).
class HeadMusic::Style::Guides::AscendingContourMelody < HeadMusic::Style::Guides::DiatonicMelody
  RULESET = contour_ruleset(:ascending, minimum_melodic_intervals: 1)
end
