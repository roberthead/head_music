# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Checks a parsed document before any of its text is read: that it
  # declares no entities, since REXML expands them lazily and a billion
  # laughs would otherwise parse, and that its root is a score.
  class ParsePreflight
    PREDEFINED_ENTITIES = %w[gt lt quot apos].freeze
    ROOTS = %w[score-partwise score-timewise].freeze

    def self.check!(xml)
      new(xml).check!
    end

    def initialize(xml)
      @xml = xml
    end

    def check!
      ensure_no_entities
      ensure_score_root
    end

    private

    attr_reader :xml

    def ensure_no_entities
      entities = xml.doctype&.entities&.keys.to_a - PREDEFINED_ENTITIES
      raise ParseError, "MusicXML input declares entities (#{entities.first(3).join(", ")})" if entities.any?
    end

    def ensure_score_root
      root = xml.root
      raise ParseError, "MusicXML input has no root element" unless root
      return if ROOTS.include?(root.name)

      raise ParseError, "MusicXML input has a <#{root.name}> root, not <score-partwise> or <score-timewise>"
    end
  end
end
