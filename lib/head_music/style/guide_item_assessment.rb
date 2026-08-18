# A module for style analysis and guidelines.
module HeadMusic::Style; end

# One guide item applied to one voice: what the guideline found, and the
# standing the guide gave it.
#
# A frozen value object that recomputes nothing, so it can be persisted or
# compared without the analysis machinery that produced it. Tier is stamped
# here because an item is shared between guides and has no single tier.
class HeadMusic::Style::GuideItemAssessment
  attr_reader :voice, :guide_item, :tier, :marks, :fitness, :violation_key, :violation_values

  delegate :guideline, :config, :name, to: :guide_item

  def initialize(voice:, guide_item:, tier:, marks:, fitness:, violation_key: nil, violation_values: {})
    @voice = voice
    @guide_item = guide_item
    @tier = tier
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
