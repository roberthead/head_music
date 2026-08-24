# A module for style analysis and guidelines.
module HeadMusic::Style; end

# One guide applied to one voice: the grade, and the per-item findings it was
# computed from.
class HeadMusic::Style::GuideAssessment
  # The rubric has two axes, and they never cross.
  #
  # TIER is the outer one: primaries share phi^-1 of the rubric and background
  # phi^-2. The two sum to 1, so one taught rule weighs as heavily as ten
  # inherited ones together. The budgets are fixed rather than derived from how
  # many items each tier holds, because a derived share erodes -- with global
  # weights, a guide's taught rule falls from 0.200 to 0.111 of the grade as
  # eight inherited guidelines accumulate around it, while a fixed budget holds
  # at 0.206. What a guide teaches must not thin out as it inherits more.
  #
  # STRENGTH is the inner one: within a tier, a prohibition weighs twice a
  # preference, normalized by that tier's own total. It never crosses a tier
  # boundary -- a strong secondary still weighs less than a weak primary.
  #
  # Gates sit outside both. They multiply the whole rubric, so strength is inert
  # on a gate and declaring one :weak has no effect.
  TIER_BUDGETS = {
    primary: HeadMusic::GOLDEN_RATIO_INVERSE,
    secondary: HeadMusic::GOLDEN_RATIO_INVERSE**2
  }.freeze

  attr_reader :guide, :voice

  # assess_items rather than assess, because guidelines answer assess too with
  # different arguments and would fail deep inside grading instead of here.
  def initialize(guide, voice)
    unless guide.respond_to?(:assess_items)
      raise ArgumentError, "guide must respond to #assess_items(voice) (got #{guide.inspect})"
    end

    # After the check above, not before: a nil guide must fail as the missing
    # duck type rather than as a missing predicate. respond_to? rather than a
    # bare call, because a guide here is a duck type and the test doubles that
    # exercise it answer assess_items and nothing else.
    if guide.respond_to?(:composite?) && guide.composite?
      raise ArgumentError, "#{guide.inspect} grades its members separately -- use guide.assess(voice)"
    end

    @guide = guide
    @voice = voice
  end

  def messages
    guide_item_assessments.reject(&:adherent?).map(&:message)
  end

  # The leaf half of the composite protocol: a consumer walks assessments and
  # never asks whether it holds one guide's grade or several.
  def assessments
    [self]
  end

  # One group of one, so a leaf and a composite answer this the same way.
  def fitness_by_category
    {guide.respond_to?(:category) ? guide.category : nil => fitness}
  end

  def guide_item_assessments
    @guide_item_assessments ||= @guide.assess_items(voice)
  end

  # A voice failing a precondition has not earned a bad grade on the rest, so
  # the rubric is not computed and fitness is the gates alone.
  def assessable?
    gates.all?(&:adherent?)
  end

  # Gates multiply against a weighted average of the rubric. No special case
  # for an unassessable voice: an empty rubric returns 1.0 and this collapses
  # to the gates, and passing gates are exactly 1 rather than nearly so.
  def fitness
    return 1.0 if guide_item_assessments.empty?

    @fitness ||= gate_factor * rubric_fitness
  end

  def adherent?
    guide_item_assessments.all?(&:adherent?)
  end

  # Public because a composite grades on its members' gate factors when one of
  # them is unassessable. Seeded with 1.0 rather than 1 so a gate-less guide
  # answers a Float, as every other fitness on this class does.
  def gate_factor
    gates.map(&:fitness).reduce(1.0, :*)
  end

  private

  def gates
    guide_item_assessments.select(&:gate?)
  end

  def rubric
    guide_item_assessments.reject(&:gate?)
  end

  # Divides by the actual weight sum rather than by an assumed total of 1, so a
  # rubric of one tier takes the full range instead of capping at its budget.
  def rubric_fitness
    return 1.0 if rubric.empty?

    weighted = rubric_weights
    total = weighted.sum { |_assessment, weight| weight }
    return 1.0 if total.zero?

    weighted.sum { |assessment, weight| weight * assessment.fitness } / total
  end

  # Pairs rather than a parallel array: the natural group_by(&:tier) refactor
  # mis-pairs a positional array silently, with no exception and a swapped
  # weight still landing in [0, 1].
  #
  # Equal weights are computed as an unweighted mean: scaling by phi^-1/n and
  # dividing back out is exact in real arithmetic and lossy in binary, and
  # nearly every guide is all-primary. A uniform-strength tier still collapses
  # this way -- every item gets budget * 2 / 2n -- so the branch stops firing
  # only when a tier actually mixes strengths. Units come from the rubric, so a
  # tier nobody declared cannot divide by zero.
  def rubric_weights
    units = rubric.group_by(&:tier).transform_values { |assessments| assessments.sum { |a| strength_units(a) } }
    raw = rubric.map { |assessment| TIER_BUDGETS.fetch(assessment.tier) * strength_units(assessment) / units[assessment.tier] }
    weights = raw.uniq.one? ? Array.new(raw.size, 1.0) : raw
    rubric.zip(weights)
  end

  # fetch, so a strength that slipped past normalization raises rather than
  # multiplying by nil.
  def strength_units(assessment)
    HeadMusic::Style::Guideline::Strength.units(assessment.strength)
  end
end
