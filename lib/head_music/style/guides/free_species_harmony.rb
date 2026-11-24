# Module for guides
module HeadMusic::Style::Guides; end

# Rules for two voices composed together in species technique with no cantus
# firmus. What it teaches is the free treatment of dissonance between two
# moving lines, the clausula vera, and textures independent of each other;
# the two-part craft of the species is background, as everywhere. A suspension
# may be struck again rather than tied.
#
# Configured with bars: an Integer or Range of bars. Length is an exercise's
# requirement rather than what the guide teaches, so it is background too, and
# setting it never changes the weight of anything else.
class HeadMusic::Style::Guides::FreeSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  def self.items_by_tier(bars: nil)
    normalize(
      gate: HARMONIC_GATES,
      primary: [
        HeadMusic::Style::Guidelines::FreeDissonanceTreatment,
        HeadMusic::Style::Guidelines::ClausulaVera,
        HeadMusic::Style::Guidelines::IndependentTextures
      ],
      secondary: [
        *(INHERITED_HARMONIC_CRAFT - [HeadMusic::Style::Guidelines::ConsonantDownbeats]),
        HeadMusic::Style::Guidelines::ConsonantDownbeats.with(restruck_suspensions: true),
        HeadMusic::Style::Guidelines::ContinueAfterDoubleNeighbor,
        (HeadMusic::Style::Guidelines::BarCount.with(bars) if bars)
      ]
    )
  end
end
