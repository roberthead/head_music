# Module for guides
module HeadMusic::Style::Guides; end

# Base class for species harmony guides. Inherits analysis behavior from Base;
# exists as a semantic marker distinguishing harmony guides from melody guides.
class HeadMusic::Style::Guides::SpeciesHarmony < HeadMusic::Style::Guides::Base
  # The preconditions every harmony guide shares. A companion voice, because
  # counterpoint is a relationship and a voice alone has no harmony to assess --
  # without this the harmonic guidelines reach for a cantus firmus that is not
  # there and raise. And three notes, because a companion alone is not enough:
  # a three-note counterpoint against an empty companion, or an empty one
  # against a real cantus firmus, otherwise grades as though it were fine.
  #
  # The minimum does not vary by species. The gate asks whether there is
  # anything here to judge, not whether the density is right; FourPerBar and the
  # dissonance guidelines answer density as rubric items.
  #
  # Splatted by each subclass rather than declared here, for the reason
  # SpeciesMelody::MELODIC_GATES gives.
  HARMONIC_GATES = [
    HeadMusic::Style::Guidelines::SetAgainstAnotherVoice,
    HeadMusic::Style::Guidelines::MinimumNotes.with(3)
  ].freeze

  # Guidelines shared by every harmonic guide. Subclasses splat this into their
  # primary list: primary_items(*HARMONIC_CORE, ...species-specific rules).
  HARMONIC_CORE = [
    HeadMusic::Style::Guidelines::ApproachPerfectionContrarily,
    HeadMusic::Style::Guidelines::AvoidCrossingVoices,
    HeadMusic::Style::Guidelines::AvoidOverlappingVoices,
    HeadMusic::Style::Guidelines::ConsonantDownbeats,
    HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats,
    HeadMusic::Style::Guidelines::PreferContraryMotion,
    HeadMusic::Style::Guidelines::PreferImperfect
  ].freeze

  # Guidelines shared by the diminution species (second, third, and triple
  # meter), which set several counterpoint notes against each whole note of the
  # cantus firmus. Subclasses splat this in alongside HARMONIC_CORE.
  DIMINUTION_HARMONIC_CORE = [
    HeadMusic::Style::Guidelines::NoParallelPerfectAcrossBarline,
    HeadMusic::Style::Guidelines::NoStrongBeatUnisons
  ].freeze

  # Builds a diminution-species primary list: the shared harmonic and diminution
  # cores plus the species-specific guidelines passed in.
  def self.diminution_items(*additional)
    [*HARMONIC_CORE, *DIMINUTION_HARMONIC_CORE, *additional].freeze
  end

  # Marks every guide descending from here as a harmony guide.
  def self.category
    :harmony
  end
end
