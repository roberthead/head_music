# A free diatonic melody with a valley contour (interior nadir).
class HeadMusic::Style::Guides::ValleyContourMelody < HeadMusic::Style::Guides::DiatonicMelody
  RULESET = [
    *HeadMusic::Style::Guides::DiatonicMelody::RULESET,
    HeadMusic::Style::Guidelines::Contoured.with(:valley)
  ].freeze
end
