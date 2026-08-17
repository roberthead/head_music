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
    @config = config
    freeze
  end

  def assess(voice, tier)
    guideline.assess(voice, self, tier)
  end

  def new(voice)
    guideline.new(voice, **config)
  end

  # Layers additional configuration onto an already-configured item, e.g.
  # MinimumNotes.with(5).with(gate: true), without dropping prior options.
  def with(**more)
    self.class.new(guideline, config.merge(more))
  end

  # Mirrors the class-level predicate so build-time filters can classify any
  # entry uniformly. A per-entry gate: option takes precedence over the
  # guideline class's default.
  def default_gate?
    config.fetch(:gate, guideline.default_gate?)
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
end
