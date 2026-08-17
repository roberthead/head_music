# Rules for fourth species harmony
class HeadMusic::Style::Guides::FourthSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  gate_items(*HARMONIC_GATES)

  primary_items(
    *HARMONIC_CORE,
    HeadMusic::Style::Guidelines::NoParallelPerfectWithSyncopation,
    HeadMusic::Style::Guidelines::NoStrongBeatUnisons,
    HeadMusic::Style::Guidelines::SecondSpeciesBreak,
    HeadMusic::Style::Guidelines::SuspensionTreatment
  )
end
