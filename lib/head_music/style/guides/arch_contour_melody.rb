# A free diatonic melody with an arch contour (interior climax).
class HeadMusic::Style::Guides::ArchContourMelody < HeadMusic::Style::Guides::DiatonicMelody
  RULESET = contour_ruleset(:arch, minimum_melodic_intervals: 2)
end
