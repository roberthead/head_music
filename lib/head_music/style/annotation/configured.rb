class HeadMusic::Style::Annotation
  # A RULESET entry pairing a guideline class with configuration. Quacks like a
  # class to the analyze loop by responding to #new(voice).
  class Configured
    attr_reader :guideline_class, :options

    def initialize(guideline_class, options)
      @guideline_class = guideline_class
      @options = options
    end

    def new(voice)
      guideline_class.new(voice, **options)
    end

    # Layers additional options onto an already-configured entry, e.g.
    # MinimumNotes.with(5).with(gate: true), without dropping prior options.
    def with(**more)
      Configured.new(guideline_class, options.merge(more))
    end

    # Mirrors the class-level predicate so build-time RULESET filters can
    # classify any entry (bare class or configured) uniformly. A per-entry
    # gate: option takes precedence over the guideline class's default.
    def default_gate?
      options.fetch(:gate, guideline_class.default_gate?)
    end

    def name
      guideline_class.name
    end
    alias_method :to_s, :name
    alias_method :inspect, :name
  end
end
