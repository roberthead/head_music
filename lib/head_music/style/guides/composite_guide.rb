# Module for guides
module HeadMusic::Style::Guides; end

# Several guides graded together as one -- a species is a melody guide and a
# harmony guide, and a student submits one line to be judged by both.
#
# Stands in for a guide class wherever one is expected, the way Configured does,
# and is registered the same way: as an instance among the classes.
#
# COMPOSES GRADES, NOT ITEMS. The tempting shape -- one guide whose items are
# the union of its members' -- is wrong twice, and the second reason is the one
# that matters.
#
# It cannot be built: a melody guide and its harmony partner both gate on
# MinimumNotes.with(3), GuideItem equality is by value, and Base.reject_duplicates
# refuses the union outright.
#
# And it would undo the tier budgets. Those exist so that what a guide teaches
# does not thin out as inherited craft accumulates around it -- see the comment
# in GuideAssessment. Merging first species puts nineteen primaries into a single
# phi^-1 budget and halves every taught rule's share, which is that erosion
# arrived at from a different direction. The two levels also grade by different
# arithmetic on purpose: rules inside a rubric trade off against each other by
# weight, while a melody grade and a harmony grade must both hold.
#
# So guide_items here is FOR DISPLAY, NOT FOR GRADING. It is deduplicated, and a
# fully graded composite therefore reports more item assessments than it has
# items -- 27 against 26 for first species, because each member assesses the
# shared gate itself.
class HeadMusic::Style::Guides::CompositeGuide
  attr_reader :guides

  # Members resolved eagerly, for the reason Configured resolves its own: a bad
  # member should raise here rather than mid-grading.
  #
  # Nothing here may ask for key, display_name, or instruction. All three read
  # Guide::REGISTRY, which does not exist yet while the registry's second pass is
  # constructing composites, and reaching for it fails on require.
  def initialize(*guides)
    @guides = guides.flatten.freeze
    reject_bad_members!
    # Both memoize, and this object freezes: anything lazy must be resolved here
    # or its first reader raises FrozenError.
    guide_items
    categories
    freeze
  end

  def assess(voice)
    HeadMusic::Style::CompositeAssessment.new(self, voice)
  end

  # Every finding, flattened. Deliberately not what the grade is computed from --
  # GuideAssessment refuses a composite, so this cannot silently become the
  # grading path.
  def assess_items(voice)
    guides.flat_map { |guide| guide.assess_items(voice) }
  end

  def guide_items
    @guide_items ||= HeadMusic::Style::Guides::Base::TIERS.flat_map { |tier| items_by_tier[tier] }.freeze
  end

  # Deduplicated within each tier rather than across the whole list, so a rule a
  # guide gates on and another grades on stays two entries -- the distinction
  # Base.reject_duplicates exists to protect.
  def items_by_tier
    @items_by_tier ||= HeadMusic::Style::Guides::Base::TIERS.to_h { |tier|
      [tier, guides.flat_map { |guide| guide.items_by_tier[tier] }.uniq.freeze]
    }.freeze
  end

  def composite?
    true
  end

  # A composite spans its members' categories rather than claiming one. Consumers
  # grouping the registry by category get a nil bucket; categories is the answer.
  def category
    nil
  end

  def categories
    @categories ||= guides.flat_map(&:categories).uniq.freeze
  end

  # Reverse lookup, not derivation, matching Configured: an unregistered
  # composite has no key rather than claiming one that resolves elsewhere.
  def key
    HeadMusic::Style::Guide.key_for(self)
  end

  def display_name
    key ? HeadMusic::Style::Guide.display_name_for(key) : guides.map(&:display_name).join(" + ")
  end

  # An unregistered composite borrows its members' instructions rather than
  # rendering a template no locale has.
  def instruction
    key ? HeadMusic::Style::Guide.instruction_for(key) : guides.map(&:instruction).join(" ")
  end

  def ==(other)
    other.is_a?(self.class) && guides == other.guides
  end
  alias_method :eql?, :==

  def hash
    guides.hash
  end

  def name
    guides.map(&:name).join(" + ")
  end
  alias_method :to_s, :name

  def inspect
    "#{self.class.name}(#{guides.map { |guide| guide.key || guide.name }.join(", ")})"
  end

  private

  # Nesting is refused rather than left unspecified. At depth two, `assessments`
  # would have to mean both the members that fitness divides by and the leaves a
  # consumer walks, and those stop being the same list.
  def reject_bad_members!
    raise ArgumentError, "a composite grades more than one guide" if guides.length < 2

    nested = guides.select { |guide| guide.respond_to?(:composite?) && guide.composite? }
    return if nested.empty?

    raise ArgumentError, "a composite cannot hold another composite: #{nested.map(&:inspect).join(", ")}"
  end
end
