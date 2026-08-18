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

  # Partitioned by membership rather than at the call site, because guides do
  # not declare the cores the same way -- some splat the constant, some name its
  # members -- and a hand-named inherited guideline must still be demoted.
  def self.species_items(*entries)
    inherited, taught = entries.flatten.compact.partition do |entry|
      INHERITED_MELODIC_CRAFT.include?(entry)
    end
    secondary_items(*inherited) if inherited.any?
    primary_items(*taught) if taught.any?
  end

  def self.moving_species_items(*additional)
    [*MELODIC_CORE, *MOVING_MELODIC_CORE, *additional].freeze
  end

  def self.category
    :melody
  end
end
