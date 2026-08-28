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

  # What a diminution species inherits: both cores, splatted into one
  # secondary_items call so that adding to either reaches all four guides.
  DIMINUTION_HARMONIC_CRAFT = [*HARMONIC_CORE, *DIMINUTION_HARMONIC_CORE].freeze

  # The tier policy, not a mechanism: every harmony guide declares its own tiers
  # outright, and this list is what base_spec holds them to -- no member of it
  # may sit in a guide's primary tier, because a species guide is about the
  # dissonance treatment its rhythm makes possible and two-part craft is
  # background.
  #
  # Wider than either splat by one. NoParallelPerfectWithSyncopation is declared
  # by hand in the only two guides that want it, so it is in no core constant,
  # but it is the same prohibition as the other three specialized for
  # syncopation: primary it would take phi^-1 of fourth and fifth species by
  # itself.
  #
  # A deliberate promotion is not written here -- removing a member would relax
  # the policy for all seven guides -- but in HARMONIC_CRAFT_PROMOTIONS below,
  # which names the exception and the one guide it applies to.
  INHERITED_HARMONIC_CRAFT = [
    *DIMINUTION_HARMONIC_CRAFT,
    HeadMusic::Style::Guidelines::NoParallelPerfectWithSyncopation
  ].freeze

  # The named exceptions to the policy above: guide key => the inherited items
  # that guide weighs as taught rules. Every promotion is written down once
  # here, so that a tier declaration in a guide can be read as a decision rather
  # than as an oversight, and so that base_spec can hold the other guides to the
  # policy without hard-coding which one departs from it.
  #
  # NoParallelPerfectOnDownbeats is primary in first species alone. First
  # species has no dissonance treatment to be about -- its other two primaries
  # are rhythm-and-texture bookkeeping -- so note-against-note consonance
  # handling is what the species teaches. In the six guides that do teach a
  # dissonance treatment, promoting it would weigh the prohibition as heavily as
  # the treatment the guide exists for, and would raise the grade of a
  # submission already failing that treatment by halving the weight it forgoes.
  #
  # Keyed by key string rather than class constant: head_music.rb loads this
  # file before the guides that subclass it, so a class reference here is a
  # load-time NameError.
  HARMONIC_CRAFT_PROMOTIONS = {
    "first_species_harmony" => [HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats]
  }.freeze

  def self.category
    :harmony
  end
end
