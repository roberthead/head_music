# Module for guides
module HeadMusic::Style::Guides; end

# Base class for style guides. A guide analyzes a voice against its ruleset,
# producing one annotation per rule.
class HeadMusic::Style::Guides::Base
  def self.analyze(voice)
    ruleset.map { |rule| rule.new(voice) }
  end

  # Indirection, not a constant read: guides whose ruleset varies by
  # configuration override this with a keyword signature, so an unconfigured
  # use raises instead of silently inheriting an ancestor's RULESET.
  def self.ruleset
    self::RULESET
  end

  # Pairs this guide with configuration: ContourMelody.with(contour: :arch).
  #
  # A guide gains configuration by declaring keywords on .ruleset, so a ruleset
  # taking none accepts none. Saying that here, at configuration time, is the
  # same choice ContourMelody makes in normalizing its contour in .with: the
  # alternative is Ruby's bare "wrong number of arguments (given 1, expected 0)"
  # at the first analyze, mid-grading, naming neither the guide nor the option.
  def self.with(**options)
    if options.any? && method(:ruleset).parameters.empty?
      raise ArgumentError, "#{name} takes no configuration, so it cannot be given: #{options.keys.join(", ")}"
    end

    HeadMusic::Style::Guides::Configured.new(self, options)
  end

  def self.key
    HeadMusic::Utilities::Case.to_snake_case(name.split("::").last)
  end

  # An open enum owned by the gem: :melody or :harmony today, with room for
  # :rhythm or :form later. Declared on the semantic marker base classes.
  def self.category
    nil
  end

  def self.display_name
    HeadMusic::Style::Guide.display_name_for(key)
  end
end
