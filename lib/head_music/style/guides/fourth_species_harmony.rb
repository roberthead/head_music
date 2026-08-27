# Rules for fourth species harmony
class HeadMusic::Style::Guides::FourthSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  gate_items(*HARMONIC_GATES)

  primary_items(
    HeadMusic::Style::Guidelines::SecondSpeciesBreak,
    HeadMusic::Style::Guidelines::SuspensionTreatment
  )

  secondary_items(
    *HARMONIC_CORE,
    HeadMusic::Style::Guidelines::NoParallelPerfectWithSyncopation,
    HeadMusic::Style::Guidelines::NoStrongBeatUnisons
  )
end
