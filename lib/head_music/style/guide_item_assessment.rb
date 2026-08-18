# A module for style analysis and guidelines.
module HeadMusic::Style; end

# One guide item applied to one voice: what the guideline found, and the
# standing the guide gave it.
#
# A frozen value object. It recomputes nothing, so it can be handed around,
# compared, or persisted without carrying the analysis machinery that produced
# it -- which is why Guideline.assess builds one of these rather than handing
# back the analyzer instance.
#
# Tier is stamped here rather than read off the item, because a guide item is
# shared between guides and has no single tier. An assessment belongs to one
# analysis and never is.
class HeadMusic::Style::GuideItemAssessment
  attr_reader :voice, :guide_item, :tier, :marks, :fitness, :violation_key, :violation_values

  # Including the name, which is the item's to give: what a guide calls a
  # guideline it configured, not what the class is called.
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

  # Nil when there is nothing to complain about. A guideline that found no
  # fault has no violation to report, and saying one anyway is how a consumer
  # ends up showing a student a rule they did not break.
  #
  # Rendered through the guideline rather than through Template directly, so
  # this path and GuideItem#violation_preview are one seam: rendering here on
  # its own left the student-facing sentence without the plural fallback the
  # preview had.
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
