# A free diatonic melody with a descending contour (departs its ceiling, arrives at its floor).
class HeadMusic::Style::Guides::DescendingContourMelody < HeadMusic::Style::Guides::DiatonicMelody
  RULESET = contour_ruleset(:descending, minimum_melodic_intervals: 1)
end
