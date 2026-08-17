# Module for guides
module HeadMusic::Style::Guides; end

# Rules for fifth species (florid) harmony
class HeadMusic::Style::Guides::FifthSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  gate_items(*HARMONIC_GATES)

  primary_items(
    *HARMONIC_CORE,
    HeadMusic::Style::Guidelines::FloridDissonanceTreatment,
    HeadMusic::Style::Guidelines::NoParallelPerfectAcrossBarline,
    HeadMusic::Style::Guidelines::NoParallelPerfectWithSyncopation,
    HeadMusic::Style::Guidelines::NoStrongBeatUnisons,
    HeadMusic::Style::Guidelines::SuspensionTreatment
  )
end
