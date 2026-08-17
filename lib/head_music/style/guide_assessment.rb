# A module for style analysis and guidelines.
module HeadMusic::Style; end

# One guide applied to one voice: the grade, and the per-item findings it was
# computed from.
class HeadMusic::Style::GuideAssessment
  # Primaries -- what the guide is about -- share phi^-1 of the rubric, and the
  # background it inherits shares phi^-2. The two sum to 1, so a guide that
  # teaches one thing against ten inherited ones grades the lesson as heavily
  # as everything else together.
  TIER_BUDGETS = {
    primary: HeadMusic::GOLDEN_RATIO_INVERSE,
    secondary: HeadMusic::GOLDEN_RATIO_INVERSE**2
  }.freeze

  attr_reader :guide, :voice

  # Any object that can assess a whole voice item by item is a guide here --
  # a guide class, a Guides::Configured, or a test double. Checking for
  # assess_items rather than assess is what keeps a guideline out: guidelines
  # and guide items answer assess too, with different arguments, so a bare
  # respond_to?(:assess) would let one through and fail deep inside grading.
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

  # The grade: gates multiply against a weighted average of the rubric, so a
  # voice that fails a precondition scales the whole grade down while the
  # things the guide teaches trade off against each other by tier.
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

  # A rubric whose weights are all equal is an unweighted mean, and is computed
  # as one: scaling every term by phi^-1/n and dividing the sum back out is
  # exact in real arithmetic and lossy in binary. Nearly every guide is
  # all-primary, so the naive form would drift about an ulp on most of them --
  # enough to change a grade that should not have changed at all.
  #
  # Counts come from the rubric rather than from the guide, so a tier nobody
  # declared cannot divide by zero.
  def rubric_weights
    counts = rubric.group_by(&:tier).transform_values(&:size)
    raw = rubric.map { |assessment| TIER_BUDGETS.fetch(assessment.tier) / counts[assessment.tier] }
    raw.uniq.one? ? Array.new(raw.size, 1.0) : raw
  end
end
