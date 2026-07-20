# Module for guides
module HeadMusic::Style::Guides; end

# Base class for species harmony guides. Inherits analysis behavior from Base;
# exists as a semantic marker distinguishing harmony guides from melody guides.
class HeadMusic::Style::Guides::SpeciesHarmony < HeadMusic::Style::Guides::Base
  # Guidelines shared by every harmonic guide. Subclasses splat this into their
  # RULESET: RULESET = [*HARMONIC_CORE, ...species-specific rules].
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

  # Builds a diminution-species RULESET: the shared harmonic and diminution
  # cores plus the species-specific guidelines passed in.
  def self.diminution_ruleset(*additional)
    [*HARMONIC_CORE, *DIMINUTION_HARMONIC_CORE, *additional].freeze
  end
end
