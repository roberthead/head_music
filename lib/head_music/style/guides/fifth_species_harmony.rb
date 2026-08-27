# Module for guides
module HeadMusic::Style::Guides; end

# Rules for fifth species (florid) harmony
class HeadMusic::Style::Guides::FifthSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  gate_items(*HARMONIC_GATES)

  primary_items(
    HeadMusic::Style::Guidelines::FloridDissonanceTreatment,
    HeadMusic::Style::Guidelines::SuspensionTreatment
  )

  secondary_items(
    *HARMONIC_CORE,
    HeadMusic::Style::Guidelines::NoParallelPerfectAcrossBarline,
    HeadMusic::Style::Guidelines::NoParallelPerfectWithSyncopation,
    HeadMusic::Style::Guidelines::NoStrongBeatUnisons
  )
end
