# A free diatonic melody with an arch contour (interior climax).
class HeadMusic::Style::Guides::ArchContourMelody < HeadMusic::Style::Guides::DiatonicMelody
  RULESET = [
    *HeadMusic::Style::Guides::DiatonicMelody::RULESET,
    HeadMusic::Style::Guidelines::Contoured.with(:arch)
  ].freeze
end
