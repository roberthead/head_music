# Guidelines for a free diatonic melody (not bound to cantus firmus start/end constraints).
class HeadMusic::Style::Guides::DiatonicMelody < HeadMusic::Style::Guides::SpeciesMelody
  # Modern interpretation: major sixths are singable; sevenths are not.
  SINGABLE_INTERVALS = %w[P1 m2 M2 m3 M3 P4 P5 m6 M6 P8].freeze

  RULESET = [
    *(MELODIC_CORE - [HeadMusic::Style::Guidelines::SingableIntervals]),
    HeadMusic::Style::Guidelines::SingableIntervals.with(
      ascending: SINGABLE_INTERVALS,
      descending: SINGABLE_INTERVALS
    ),
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
