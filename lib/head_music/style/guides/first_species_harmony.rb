# Rules for first species harmony
class HeadMusic::Style::Guides::FirstSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  RULESET = [
    *HARMONIC_CORE,
    HeadMusic::Style::Guidelines::NoUnisonsInMiddle,
    HeadMusic::Style::Guidelines::OneToOne
  ].freeze
end

# TODO: Guideline against leaping into P8 even by contrary motion.
# TODO: Guideline allowing oblique motion < ~15% of the time.
# TODO: Guideline against battuta (10-8 not at cadence, unless 10-8-6 voice exchange)
# TODO: 16th C: No M6 leaps. m6 leaps ascending only.
# TODO: 16th C (?): Avoid perfect consonances on consecutive downbeats
# TODO: 16th C: No 5-7-1 ending
# TODO: 16th C Cantus Firmus: Raise the 7 in the cadence, except in Phrygian
