require "rexml/document"

# A module for visual music notation
module HeadMusic::Notation
  # Checks a parsed XML document before any of its text is read: that it
  # declares no entities, since REXML expands them lazily and a billion
  # laughs would otherwise parse; that its root is one the format reads; and
  # that it nests no deeper than a reader can walk.
  class ParsePreflight
    PREDEFINED_ENTITIES = %w[gt lt quot apos].freeze

    def self.check!(xml, roots:, format:, error_class:, max_depth: 256)
      new(xml, roots: roots, format: format, error_class: error_class, max_depth: max_depth).check!
    end

    def initialize(xml, roots:, format:, error_class:, max_depth: 256)
      @xml = xml
      @roots = roots
      @format = format
      @error_class = error_class
      @max_depth = max_depth
    end

    def check!
      ensure_no_entities
      ensure_root
      ensure_depth
    end

    private

    attr_reader :xml, :roots, :format, :error_class, :max_depth

    def ensure_no_entities
      entities = xml.doctype&.entities&.keys.to_a - PREDEFINED_ENTITIES
      raise error_class, "#{format} input declares entities (#{entities.first(3).join(", ")})" if entities.any?
    end

    def ensure_root
      root = xml.root
      raise error_class, "#{format} input has no root element" unless root
      return if roots.include?(root.name)

      raise error_class, "#{format} input has a <#{root.name}> root, not #{root_names}"
    end

    def root_names
      names = roots.map { |name| "<#{name}>" }
      return names.join(" or ") if names.length <= 2

      "#{names[0..-2].join(", ")}, or #{names.last}"
    end

    # An explicit stack, since a recursive walk overflows on a deep enough
    # nest and SystemStackError is no StandardError.
    def ensure_depth
      stack = [[xml.root, 1]]
      until stack.empty?
        element, depth = stack.pop
        raise error_class, "#{format} input nests elements deeper than #{max_depth}" if depth > max_depth

        element.each { |child| stack.push([child, depth + 1]) if child.is_a?(REXML::Element) }
      end
    end
  end
end
