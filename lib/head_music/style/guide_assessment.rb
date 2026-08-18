# A module for style analysis and guidelines.
module HeadMusic::Style; end

# One guide applied to one voice: the grade, and the per-item findings it was
# computed from.
class HeadMusic::Style::GuideAssessment
  # Primaries share phi^-1 of the rubric and background phi^-2. The two sum to
  # 1, so one taught rule weighs as heavily as ten inherited ones together.
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

    @guide = guide
    @voice = voice
  end

  def messages
    guide_item_assessments.reject(&:adherent?).map(&:message)
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

  private

  def gates
    guide_item_assessments.select(&:gate?)
  end

  def rubric
    guide_item_assessments.reject(&:gate?)
  end

  def gate_factor
    gates.map(&:fitness).reduce(1, :*)
  end

  def rubric_fitness
    return 1.0 if rubric.empty?

    weights = rubric_weights
    total = weights.sum
    return 1.0 if total.zero?

    rubric.each_with_index.sum { |assessment, index| weights[index] * assessment.fitness } / total
  end

  # Equal weights are computed as an unweighted mean: scaling by phi^-1/n and
  # dividing back out is exact in real arithmetic and lossy in binary, and
  # nearly every guide is all-primary. Counts come from the rubric, so a tier
  # nobody declared cannot divide by zero.
  def rubric_weights
    counts = rubric.group_by(&:tier).transform_values(&:size)
    raw = rubric.map { |assessment| TIER_BUDGETS.fetch(assessment.tier) / counts[assessment.tier] }
    raw.uniq.one? ? Array.new(raw.size, 1.0) : raw
  end
end
