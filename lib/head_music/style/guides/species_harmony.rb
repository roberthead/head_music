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

  def self.diminution_items(*additional)
    [*HARMONIC_CORE, *DIMINUTION_HARMONIC_CORE, *additional].freeze
  end

  def self.category
    :harmony
  end
end
