# A module for style analysis and guidelines.
module HeadMusic::Style; end

# A guideline plus the configuration one guide gives it, so the same guideline
# configured two ways is two items.
#
# Tier is deliberately absent: an item is shared between guides and has no
# single standing, so tier is stamped onto the assessment instead.
class HeadMusic::Style::GuideItem
  attr_reader :guideline, :config

  def self.wrap(entry)
    entry.is_a?(self) ? entry : new(entry)
  end

  # Removed options, mapped to what replaces them. An unrecognized key rides
  # along in config and is dropped at render, so a consumer who kept passing
  # message: would watch their sentence vanish without a word.
  REMOVED_OPTIONS = {message: :violation_key}.freeze

  def initialize(guideline, config = {})
    reject_removed_options!(config)
    @guideline = guideline
    @config = deep_freeze(config)
    freeze
  end

  # An assessment says nothing when adherent, so this is the only way to read
  # the sentence an item carries without a voice that breaks it.
  def violation_preview
    guideline.render_violation(config)
  end

  def assess(voice, tier)
    guideline.assess(voice, self, tier)
  end

  # By value: identity matching is what made `CORE - [Guideline]` silently
  # remove nothing.
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
  # could not.
  def inspect
    return guideline.name if config.empty?

    "#{guideline.name}#{config.inspect}"
  end
  alias_method :to_s, :inspect

  private

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
