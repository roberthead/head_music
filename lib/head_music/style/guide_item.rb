# A module for style analysis and guidelines.
module HeadMusic::Style; end

# A guideline plus the configuration one guide gives it, so the same guideline
# configured two ways is two items.
#
# Tier is deliberately absent: an item is shared between guides and has no
# single standing, so tier is stamped onto the assessment instead. Strength is
# present, because a rule's severity does not change between guides -- the
# override exists only for the tradition-dependent case, where
# ApproachPerfectionContrarily is prohibited in Fux and merely cautioned later.
class HeadMusic::Style::GuideItem
  attr_reader :guideline, :config, :strength

  def self.wrap(entry)
    entry.is_a?(self) ? entry : new(entry)
  end

  # Removed options, mapped to what replaces them. An unrecognized key rides
  # along in config and is dropped at render, so a consumer who kept passing
  # message: would watch their sentence vanish without a word.
  REMOVED_OPTIONS = {message: :violation_key}.freeze

  # Strength is resolved eagerly, before the freeze: asking the guideline for
  # it lazily during grading would write a class ivar mid-assessment.
  def initialize(guideline, config = {}, strength: nil)
    reject_removed_options!(config)
    @guideline = guideline
    @config = deep_freeze(config)
    @strength = resolve_strength(guideline, strength)
    freeze
  end

  # An assessment says nothing when adherent, so this is the only way to read
  # the sentence an item carries without a voice that breaks it.
  def violation_preview
    guideline.render_violation(config)
  end

  # Every sentence the item can produce, including the branches an analysis
  # chooses between. What load-time verification sweeps.
  def violation_previews
    guideline.render_violations(config)
  end

  def assess(voice, tier)
    guideline.assess(voice, self, tier)
  end

  # By value: identity matching is what made `CORE - [Guideline]` silently
  # remove nothing.
  #
  # Strength is deliberately omitted from both == and hash. reject_duplicates
  # asks one question -- is this rule graded twice -- and strength cannot change
  # the answer. Were it part of equality, declaring a rule primary-strong and
  # secondary-weak would slip past the guard and be double-counted.
  def ==(other)
    other.is_a?(self.class) && guideline == other.guideline && config == other.config
  end
  alias_method :eql?, :==

  def hash
    [guideline, config].hash
  end

  def name
    guideline.render_name(config)
  end

  def instruction
    guideline.render_instruction(config)
  end

  # Distinguishes two configurations of one guideline, which the class name
  # could not. Strength shows only when it differs from the declaration, so the
  # common case stays readable.
  def inspect
    overridden = (strength == guideline.strength) ? "" : "<#{strength}>"
    return "#{guideline.name}#{overridden}" if config.empty?

    "#{guideline.name}#{overridden}#{config.inspect}"
  end
  alias_method :to_s, :inspect

  private

  def resolve_strength(guideline, override)
    return guideline.strength if override.nil?

    HeadMusic::Style::Guideline::Strength.normalized(override, guideline.name)
  end

  # At declaration time, so this fails on require rather than rendering the
  # wrong sentence for the life of the process.
  def reject_removed_options!(config)
    removed = config.keys & REMOVED_OPTIONS.keys
    return if removed.empty?

    raise ArgumentError, removed.map { |option|
      "#{option}: is no longer a guideline option -- name a locale entry with #{REMOVED_OPTIONS[option]}:"
    }.join(" ")
  end

  # Deep, because items are shared between guides: a mutable array inside
  # config lets one caller corrupt every guide reusing a core, and changes the
  # hash that value equality and duplicate rejection rest on.
  #
  # Containers and strings only. A config value can be a rudiment, and those
  # memoize lazily, so freezing one breaks it the first time it is asked.
  def deep_freeze(value)
    case value
    when Hash then value.each_value { |nested| deep_freeze(nested) }.freeze
    when Array then value.each { |nested| deep_freeze(nested) }.freeze
    when String then value.freeze
    else value
    end
  end
end
