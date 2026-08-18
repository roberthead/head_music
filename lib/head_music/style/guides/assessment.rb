# Module for guides
module HeadMusic::Style::Guides; end

# The assess loop, shared by a guide class and a configured guide.
#
# Gates run first and stop the assessment when one fails: a voice that fails a
# precondition has not earned a bad grade on the rest, and stopping is what
# keeps the harmony guidelines from reaching for a companion that is not there.
module HeadMusic::Style::Guides::Assessment
  RUBRIC_TIERS = %i[primary secondary].freeze

  # Every gate runs even after one fails, so a consumer sees which
  # preconditions are unmet rather than only the first.
  def self.assess_items(voice, items_by_tier)
    gates = items_by_tier[:gate].map { |item| item.assess(voice, :gate) }
    return gates unless gates.all?(&:adherent?)

    gates + RUBRIC_TIERS.flat_map do |tier|
      items_by_tier[tier].map { |item| item.assess(voice, tier) }
    end
  end
end
