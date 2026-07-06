# A free diatonic melody with a wave contour (repeated undulation at the trend level).
class HeadMusic::Style::Guides::WaveContourMelody < HeadMusic::Style::Guides::DiatonicMelody
  RULESET = [
    *HeadMusic::Style::Guides::DiatonicMelody::RULESET,
    HeadMusic::Style::Guidelines::Contoured.with(:wave)
  ].freeze
end
