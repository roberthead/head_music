# A free diatonic melody with a static contour (narrow range, non-directional endpoints).
class HeadMusic::Style::Guides::StaticContourMelody < HeadMusic::Style::Guides::DiatonicMelody
  RULESET = [
    *HeadMusic::Style::Guides::DiatonicMelody::RULESET,
    HeadMusic::Style::Guidelines::Contoured.with(:static)
  ].freeze
end
