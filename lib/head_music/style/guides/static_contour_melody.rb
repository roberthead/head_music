# A free diatonic melody with a static contour (narrow range, non-directional endpoints).
# No motion gate: an all-repeated-note line is a legitimate static contour.
class HeadMusic::Style::Guides::StaticContourMelody < HeadMusic::Style::Guides::DiatonicMelody
  RULESET = contour_ruleset(:static)
end
