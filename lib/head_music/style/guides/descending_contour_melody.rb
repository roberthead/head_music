# A free diatonic melody with a descending contour (departs its ceiling, arrives at its floor).
class HeadMusic::Style::Guides::DescendingContourMelody < HeadMusic::Style::Guides::DiatonicMelody
  RULESET = [
    *HeadMusic::Style::Guides::DiatonicMelody::RULESET,
    HeadMusic::Style::Guidelines::Contoured.with(:descending)
  ].freeze
end
