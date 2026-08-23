# A module for style analysis and guidelines.
module HeadMusic::Style; end

# One guide item applied to one voice: what the guideline found, and the
# standing the guide gave it.
#
# A frozen value object that recomputes nothing, so it can be persisted or
# compared without the analysis machinery that produced it. Tier is stamped
# here because an item is shared between guides and has no single tier.
#
# Strength is stamped for a different reason -- an item does have a single
# strength -- namely that a persisted assessment records the severity in force
# when it was graded, so re-classifying a guideline later cannot silently
# rewrite old grades. It defaults from the item, so the direct-construction
# sites in specs and any external consumer keep working, and it is normalized
# here as well: this is a seam a caller can reach without going through
# GuideItem, and an unvalidated value would surface as a bare KeyError from
# Strength.units, far from the construction that caused it.
class HeadMusic::Style::GuideItemAssessment
  attr_reader :voice, :guide_item, :tier, :strength, :marks, :fitness, :violation_key, :violation_values

  delegate :guideline, :config, :name, to: :guide_item

  def initialize(voice:, guide_item:, tier:, marks:, fitness:,
    strength: guide_item.strength, violation_key: nil, violation_values: {})
    @voice = voice
    @guide_item = guide_item
    @tier = tier
    @strength = HeadMusic::Style::Guideline::Strength.normalized(strength, guide_item.name)
    @marks = [marks].flatten.compact.freeze
    @fitness = fitness
    @violation_key = violation_key
    @violation_values = violation_values
    freeze
  end

  def adherent?
    fitness == 1
  end

  # Nil when adherent: saying a violation anyway is how a consumer shows a
  # student a rule they did not break. Rendered through the guideline so this
  # and GuideItem#violation_preview stay one seam.
  def message
    return if adherent? || violation_key.nil?

    guideline.render_template(violation_key, config, violation_values)
  end

  def gate?
    tier == :gate
  end

  def start_position
    marks.map(&:start_position).min
  end

  def end_position
    marks.map(&:end_position).max
  end

  alias_method :to_s, :name
end
