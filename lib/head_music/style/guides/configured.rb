# Module for guides
module HeadMusic::Style::Guides; end

# A guide class paired with configuration. Quacks like a guide class to
# Style::Analysis by responding to #analyze(voice), exactly as
# Annotation::Configured quacks like a guideline class via #new(voice).
class HeadMusic::Style::Guides::Configured
  attr_reader :guide_class, :options

  def initialize(guide_class, options)
    @guide_class = guide_class
    @options = options.dup.freeze
  end

  def analyze(voice)
    ruleset.map { |rule| rule.new(voice) }
  end

  def ruleset
    @ruleset ||= guide_class.ruleset(**options)
  end

  # Re-dispatches through the guide class so layering revalidates:
  # ContourMelody.with(contour: :arch).with(contour: :spiral) still raises.
  def with(**more)
    guide_class.with(**options.merge(more))
  end

  # Reverse lookup, not derivation. An ad-hoc configuration outside the
  # registry honestly has no key rather than claiming a key that resolves
  # to a different configuration.
  def key
    HeadMusic::Style::Guide.key_for(self)
  end

  def category
    guide_class.category
  end

  def display_name
    key ? HeadMusic::Style::Guide.display_name_for(key) : guide_class.display_name
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
