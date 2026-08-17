# Module for guides
module HeadMusic::Style::Guides; end

# The assess loop, shared by a guide class and a configured guide.
#
# Gates run first and stop the assessment when one of them fails. A gate asks
# whether this voice can be assessed at all, so a voice that fails one has not
# earned a bad grade on the rest -- there was nothing there to grade. Stopping
# is also what keeps a guideline from reaching for a companion voice that is not
# there: the harmony guidelines raise on a solo voice, and their gate is what
# now prevents them from being asked.
module HeadMusic::Style::Guides::Assessment
  RUBRIC_TIERS = %i[primary secondary].freeze

  # Every gate is assessed even once one has failed, so a consumer can see which
  # preconditions are unmet rather than only the first.
  def self.assess_items(voice, items_by_tier)
    gates = items_by_tier[:gate].map { |item| item.assess(voice, :gate) }
    return gates unless gates.all?(&:adherent?)

    gates + RUBRIC_TIERS.flat_map do |tier|
      items_by_tier[tier].map { |item| item.assess(voice, tier) }
    end
  end
end
