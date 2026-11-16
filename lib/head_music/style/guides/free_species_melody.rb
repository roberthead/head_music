# Module for guides
module HeadMusic::Style::Guides; end

# Rules for each melody of a free species passage: two voices composed in
# species technique with no cantus firmus. Fifth species' note values and
# moving craft, except that a whole note may fall in any bar, each voice may
# keep one texture as long as it likes (IndependentTextures judges the pair
# instead), the final may be reached by step from either side, and a note
# may be struck again as a suspension.
#
# Configured with dotted_rhythms: true to allow tie-equivalent dots and a
# dotted quarter followed by a stepping eighth.
class HeadMusic::Style::Guides::FreeSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  def self.items_by_tier(dotted_rhythms: false)
    rhythmic_values = HeadMusic::Style::Guidelines::AllowFreeSpeciesRhythmicValues
    normalize(
      gate: MELODIC_GATES,
      primary: [dotted_rhythms ? rhythmic_values.with(dotted_rhythms: true) : rhythmic_values],
      secondary: [
        *(MOVING_MELODIC_CRAFT - [HeadMusic::Style::Guidelines::AlwaysMove, HeadMusic::Style::Guidelines::StepUpToFinalNote]),
        HeadMusic::Style::Guidelines::AlwaysMove.with(restruck_suspensions: true),
        HeadMusic::Style::Guidelines::StepToFinalNote,
        HeadMusic::Style::Guidelines::PreferLongBeforeShort
      ]
    )
  end
end
