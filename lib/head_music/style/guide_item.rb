# A module for style analysis and guidelines.
module HeadMusic::Style; end

# A guideline as used by one guide: the guideline plus the configuration that
# guide gives it. The relationship, not either end of it -- which is why a
# guideline configured one way in one guide and another way elsewhere is two
# items over one guideline class.
#
# Tier is deliberately absent. The shared cores (SpeciesMelody::MELODIC_CORE,
# SpeciesHarmony::HARMONIC_CORE) are splatted into many guides as the same
# frozen objects, and ContourMelody demotes exactly the items DiatonicMelody
# teaches, so no single item can carry one standing. Tier is the list an item
# is declared in, and it is stamped onto the assessment.
class HeadMusic::Style::GuideItem
  attr_reader :guideline, :config

  # Coerces a bare guideline class, so a declaration can mix the two forms.
  def self.wrap(entry)
    entry.is_a?(self) ? entry : new(entry)
  end

  def initialize(guideline, config = {})
    @guideline = guideline
    @config = deep_freeze(config)
    freeze
  end

  def assess(voice, tier)
    guideline.assess(voice, self, tier)
  end

  # By value, so an item can be found in a list by what it is rather than by
  # which object it is -- the identity matching that made `CORE - [Guideline]`
  # silently remove nothing.
  def ==(other)
    other.is_a?(self.class) && guideline == other.guideline && config == other.config
  end
  alias_method :eql?, :==

  def hash
    [guideline, config].hash
  end

  def name
    guideline.name
  end
  alias_method :to_s, :name
  alias_method :inspect, :name

  private

  # Deep, because freezing the item alone would be a promise it does not keep.
  # Items are built once at load and shared between guides -- the same
  # LargeLeaps item is in DiatonicMelody and all six contour guides -- so a
  # mutable array inside config lets one caller corrupt every guide that reuses
  # a core, and changes the hash of an object that reports itself frozen, which
  # is what duplicate rejection and value equality rest on.
  #
  # Containers and strings only. A config value can be a rudiment -- LargeLeaps
  # takes a DiatonicInterval as its minimum -- and those memoize lazily, so
  # freezing one breaks it the first time it is asked a question.
  def deep_freeze(value)
    case value
    when Hash then value.each_value { |nested| deep_freeze(nested) }.freeze
    when Array then value.each { |nested| deep_freeze(nested) }.freeze
    when String then value.freeze
    else value
    end
  end
end
