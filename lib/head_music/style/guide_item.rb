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

  # Options the move into locale files removed, mapped to what replaces them.
  # An unrecognized key is not an error to config -- it rides along, is offered
  # as an interpolation no template names, and is dropped -- so a consumer who
  # kept passing message: would watch their sentence vanish without a word.
  REMOVED_OPTIONS = {message: :violation_key}.freeze

  def initialize(guideline, config = {})
    reject_removed_options!(config)
    @guideline = guideline
    @config = deep_freeze(config)
    freeze
  end

  # The violation this item would report, without needing a voice that breaks
  # it. An assessment says nothing when adherent, so previewing is the only way
  # to read the sentence a guide item carries.
  def violation_preview
    guideline.render_violation(config)
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

  # What this item is called, and what it asks for -- both rendered, because
  # both say what this guide configured rather than what the guideline is in
  # the abstract.
  def name
    guideline.render_name(config)
  end

  def instruction
    guideline.render_instruction(config)
  end

  # Identifies the item rather than describing it, and distinguishes two
  # configurations of one guideline, which printing the class name could not.
  def inspect
    return guideline.name if config.empty?

    "#{guideline.name}#{config.inspect}"
  end
  alias_method :to_s, :inspect

  private

  # At declaration time, so a guide naming a removed option fails on require
  # rather than rendering the wrong sentence for the life of the process.
  def reject_removed_options!(config)
    removed = config.keys & REMOVED_OPTIONS.keys
    return if removed.empty?

    raise ArgumentError, removed.map { |option|
      "#{option}: is no longer a guideline option -- name a locale entry with #{REMOVED_OPTIONS[option]}:"
    }.join(" ")
  end

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
