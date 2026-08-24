# Module for guides
module HeadMusic::Style::Guides; end

# A guide class paired with configuration. Stands in for a guide class
# wherever one is expected by answering assess(voice) and assess_items(voice).
class HeadMusic::Style::Guides::Configured
  attr_reader :guide_class, :options

  def initialize(guide_class, options)
    @guide_class = guide_class
    @options = options.dup.freeze
    guide_items # Resolve now, so a bad configuration raises here rather than mid-grading.
  end

  def assess(voice)
    HeadMusic::Style::GuideAssessment.new(self, voice)
  end

  def assess_items(voice)
    HeadMusic::Style::Guides::Assessment.assess_items(voice, items_by_tier)
  end

  def guide_items
    @guide_items ||= HeadMusic::Style::Guides::Base::TIERS.flat_map { |tier| items_by_tier[tier] }.freeze
  end

  def items_by_tier
    @items_by_tier ||= guide_class.items_by_tier(**options)
  end

  # Through the guide class, so layering revalidates: .with(contour: :spiral)
  # on an already-configured guide still raises.
  def with(**more)
    guide_class.with(**options.merge(more))
  end

  # Reverse lookup, not derivation: an ad-hoc configuration has no key rather
  # than claiming one that resolves to a different configuration.
  def key
    HeadMusic::Style::Guide.key_for(self)
  end

  def category
    guide_class.category
  end

  def composite?
    false
  end

  # The guide-side twin of GuideAssessment#assessments: one category, so a
  # registry sweep can ask every entry the same question.
  def categories
    [category].compact
  end

  def display_name
    key ? HeadMusic::Style::Guide.display_name_for(key) : guide_class.display_name
  end

  # An unregistered configuration borrows the instruction of the guide it
  # configures.
  def instruction
    key ? HeadMusic::Style::Guide.instruction_for(key) : guide_class.instruction
  end

  def ==(other)
    other.is_a?(self.class) && guide_class == other.guide_class && options == other.options
  end
  alias_method :eql?, :==

  def hash
    [guide_class, options].hash
  end

  def name
    guide_class.name
  end
  alias_method :to_s, :name

  def inspect
    "#{guide_class.name}.with(#{options.inspect})"
  end
end
