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
  attr_reader :voice, :guide_item, :tier, :marks, :fitness, :message

  delegate :guideline, :config, to: :guide_item

  def initialize(voice:, guide_item:, tier:, marks:, fitness:, message: nil)
    @voice = voice
    @guide_item = guide_item
    @tier = tier
    @marks = [marks].flatten.compact.freeze
    @fitness = fitness
    @message = message
    freeze
  end

  def adherent?
    fitness == 1
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

  def name
    guideline.name
  end
  alias_method :to_s, :name
end
