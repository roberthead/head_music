# A free diatonic melody with an ascending contour (departs its floor, arrives at its ceiling).
class HeadMusic::Style::Guides::AscendingContourMelody < HeadMusic::Style::Guides::DiatonicMelody
  RULESET = [
    *HeadMusic::Style::Guides::DiatonicMelody::RULESET,
    HeadMusic::Style::Guidelines::Contoured.with(:ascending)
  ].freeze
end
