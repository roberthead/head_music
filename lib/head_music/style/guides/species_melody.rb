# Module for guides
module HeadMusic::Style::Guides; end

# Base class for species melody guides. Inherits analysis behavior from Base;
# exists as a semantic marker distinguishing melody guides from harmony guides.
class HeadMusic::Style::Guides::SpeciesMelody < HeadMusic::Style::Guides::Base
  # Three notes is where a contour becomes possible at all.
  #
  # Splatted by each subclass rather than declared here: declarations are a
  # per-class ivar, so gate_items here would leave every subclass ungated, and
  # normalize would not object because the subclasses have primaries.
  MELODIC_GATES = [
    HeadMusic::Style::Guidelines::MinimumNotes.with(3)
  ].freeze

  MELODIC_CORE = [
    HeadMusic::Style::Guidelines::ConsonantClimax,
    HeadMusic::Style::Guidelines::Diatonic,
    HeadMusic::Style::Guidelines::LimitOctaveLeaps,
    HeadMusic::Style::Guidelines::MostlyConjunct,
    HeadMusic::Style::Guidelines::SingableIntervals,
    HeadMusic::Style::Guidelines::SingableRange
  ].freeze

  # For the moving species (second through fifth), whose melodies progress
  # within the bar rather than holding a whole note.
  #
  # Two of these read as harmonic rules and neither moves to the harmonic cores.
  # StartOnPerfectConsonance is not harmonic despite its name -- it measures the
  # interval from the key's tonic, not from the companion voice, so it scores a
  # solo voice legitimately. StepOutOfUnison genuinely is harmonic and does score
  # a free 1.0 for a solo voice, but that free-1.0 belongs to the identification
  # problem rather than to a weighting question, and moving it costs six
  # assertions across the melody specs to buy 0.007 of one harmony grade.
  #
  # Whoever revisits this must fix both call sites: FirstSpeciesMelody and
  # CombinedFirstSecondThirdSpeciesMelody name these two by hand, so dropping
  # them from INHERITED_MELODIC_CRAFT would send them to primary_items -- a
  # background rule graded as a taught rule -- while the guides that splat
  # moving_species_items would simply lose them.
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

  # A species guide is about its rhythm; melodic craft is background.
  INHERITED_MELODIC_CRAFT = (MELODIC_CORE + MOVING_MELODIC_CORE).freeze

  def self.species_items(*entries)
    tier_by_membership(entries, INHERITED_MELODIC_CRAFT)
  end

  def self.moving_species_items(*additional)
    [*MELODIC_CORE, *MOVING_MELODIC_CORE, *additional].freeze
  end

  def self.category
    :melody
  end
end
