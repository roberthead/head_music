# Module for guides
module HeadMusic::Style::Guides; end

# Base class for species melody guides. Inherits analysis behavior from Base;
# exists as a semantic marker distinguishing melody guides from harmony guides.
class HeadMusic::Style::Guides::SpeciesMelody < HeadMusic::Style::Guides::Base
  # The precondition every species melody guide shares: three notes is where a
  # contour becomes possible at all, and below it the melodic guidelines have
  # nothing to look at.
  #
  # Splatted by each subclass rather than declared here. Declarations live in a
  # per-class singleton ivar, so gate_items on this class would leave every
  # subclass with an empty gate list -- and would not raise, because normalize
  # only objects when all three tiers are empty and the subclasses have
  # primaries. The suite would stay green with nothing gated.
  MELODIC_GATES = [
    HeadMusic::Style::Guidelines::MinimumNotes.with(3)
  ].freeze

  # Guidelines shared by every melodic guide. Subclasses splat this into their
  # primary list: primary_items(*MELODIC_CORE, ...species-specific rules).
  MELODIC_CORE = [
    HeadMusic::Style::Guidelines::ConsonantClimax,
    HeadMusic::Style::Guidelines::Diatonic,
    HeadMusic::Style::Guidelines::LimitOctaveLeaps,
    HeadMusic::Style::Guidelines::MostlyConjunct,
    HeadMusic::Style::Guidelines::SingableIntervals,
    HeadMusic::Style::Guidelines::SingableRange
  ].freeze

  # Guidelines shared by every moving species (second through fifth), whose
  # melodies progress within the bar rather than holding a whole note as in
  # first species. Subclasses splat this in alongside MELODIC_CORE.
  MOVING_MELODIC_CORE = [
    HeadMusic::Style::Guidelines::AlwaysMove,
    HeadMusic::Style::Guidelines::EndOnTonic,
    HeadMusic::Style::Guidelines::FrequentDirectionChanges,
    HeadMusic::Style::Guidelines::NoRestsAfterNote,
    HeadMusic::Style::Guidelines::NoteFillsFinalBar,
    HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
    HeadMusic::Style::Guidelines::StartOnPerfectConsonance,
    HeadMusic::Style::Guidelines::StepOutOfUnison,
    HeadMusic::Style::Guidelines::StepUpToFinalNote
  ].freeze

  # Builds a moving-species primary list: the shared melodic and moving cores plus
  # the species-specific guidelines passed in.
  def self.moving_species_items(*additional)
    [*MELODIC_CORE, *MOVING_MELODIC_CORE, *additional].freeze
  end

  # Marks every guide descending from here as a melody guide.
  def self.category
    :melody
  end
end
