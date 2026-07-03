# Guidelines for a free diatonic melody (not bound to cantus firmus start/end constraints).
class HeadMusic::Style::Guides::DiatonicMelody < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    *MELODIC_CORE,
    HeadMusic::Style::Guidelines::ModerateDirectionChanges,
    HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
    HeadMusic::Style::Guidelines::SingleLargeLeaps,
    HeadMusic::Style::Guidelines::MinimumNotes.with(5),
    HeadMusic::Style::Guidelines::MaximumNotes.with(24)
  ].freeze
end
