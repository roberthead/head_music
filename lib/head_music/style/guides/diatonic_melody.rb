# Guidelines for a free diatonic melody (not bound to cantus firmus start/end constraints).
class HeadMusic::Style::Guides::DiatonicMelody < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    *MELODIC_CORE,
    HeadMusic::Style::Guidelines::ModerateDirectionChanges,
    HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
    HeadMusic::Style::Guidelines::LargeLeaps.with(
      minimum: :perfect_fourth,
      recovery: %i[consonant_triad any_step repetition opposite_leap_within]
    ),
    HeadMusic::Style::Guidelines::MinimumNotes.with(5),
    HeadMusic::Style::Guidelines::MaximumNotes.with(32)
  ].freeze
end
