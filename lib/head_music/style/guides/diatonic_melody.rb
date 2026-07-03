# Guidelines for a free diatonic melody (not bound to cantus firmus start/end constraints).
class HeadMusic::Style::Guides::DiatonicMelody < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    HeadMusic::Style::Guidelines::MinimumNotes.with(minimum: 5),
    HeadMusic::Style::Guidelines::ConsonantClimax,
    HeadMusic::Style::Guidelines::Diatonic,
    HeadMusic::Style::Guidelines::LimitOctaveLeaps,
    HeadMusic::Style::Guidelines::ModerateDirectionChanges,
    HeadMusic::Style::Guidelines::MostlyConjunct,
    HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
    HeadMusic::Style::Guidelines::SingableIntervals,
    HeadMusic::Style::Guidelines::SingableRange,
    HeadMusic::Style::Guidelines::SingleLargeLeaps,
    HeadMusic::Style::Guidelines::MaximumNotes.with(maximum: 24)
  ].freeze
end
