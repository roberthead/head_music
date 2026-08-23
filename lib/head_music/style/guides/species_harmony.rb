# Module for guides
module HeadMusic::Style::Guides; end

# Base class for species harmony guides. Inherits analysis behavior from Base;
# exists as a semantic marker distinguishing harmony guides from melody guides.
class HeadMusic::Style::Guides::SpeciesHarmony < HeadMusic::Style::Guides::Base
  # A companion voice, without which the harmonic guidelines reach for a cantus
  # firmus that is not there and raise; and three notes, without which a voice
  # against an empty companion grades as though it were fine.
  #
  # The gate asks whether there is anything to judge, not whether the density is
  # right. Splatted by each subclass, for the reason MELODIC_GATES gives.
  HARMONIC_GATES = [
    HeadMusic::Style::Guidelines::SetAgainstAnotherVoice,
    HeadMusic::Style::Guidelines::MinimumNotes.with(3)
  ].freeze

  HARMONIC_CORE = [
    HeadMusic::Style::Guidelines::ApproachPerfectionContrarily,
    HeadMusic::Style::Guidelines::AvoidCrossingVoices,
    HeadMusic::Style::Guidelines::AvoidOverlappingVoices,
    HeadMusic::Style::Guidelines::ConsonantDownbeats,
    HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats,
    HeadMusic::Style::Guidelines::PreferContraryMotion,
    HeadMusic::Style::Guidelines::PreferImperfect
  ].freeze

  # For the diminution species, which set several counterpoint notes against
  # each whole note of the cantus firmus.
  DIMINUTION_HARMONIC_CORE = [
    HeadMusic::Style::Guidelines::NoParallelPerfectAcrossBarline,
    HeadMusic::Style::Guidelines::NoStrongBeatUnisons
  ].freeze

  # A species guide is about the dissonance treatment its rhythm makes possible;
  # two-part craft is background.
  #
  # NoParallelPerfectWithSyncopation is a member of neither constant and is not
  # put into one, because only the two syncopated species declare it and the
  # constants are splatted wholesale. It belongs here all the same: it is the
  # same prohibition as the other three, specialized for syncopation, and left
  # primary it would take phi^-1 of fourth and fifth species by itself.
  INHERITED_HARMONIC_CRAFT = [
    *HARMONIC_CORE,
    *DIMINUTION_HARMONIC_CORE,
    HeadMusic::Style::Guidelines::NoParallelPerfectWithSyncopation
  ].freeze

  def self.species_items(*entries)
    tier_by_membership(entries, INHERITED_HARMONIC_CRAFT)
  end

  # Concatenation only, now that tiering is decided by membership. Kept for the
  # symmetry with SpeciesMelody.moving_species_items, which reads the same way at
  # the four call sites that splat it.
  def self.diminution_items(*additional)
    [*HARMONIC_CORE, *DIMINUTION_HARMONIC_CORE, *additional].freeze
  end

  def self.category
    :harmony
  end
end
