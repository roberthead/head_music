module HeadMusic::Notation::MEI
  # The fixed editorial rule: every walk of the music asks for an element's
  # children here, and gets the one reading of them this reader keeps.
  #
  # - <app> takes its <lem>, or else its first <rdg>.
  # - <choice> takes its <corr>, else its <reg>, else its <expan>, wherever
  #   each stands among its children, or else its first child.
  # - <subst> takes its <add>.
  # - <supplied>, <add>, <unclear>, <restore>, <damage>, and the other
  #   members of a choice give their contents.
  # - <del> gives nothing.
  #
  # An element with a @copyof reads as the copy CopyExpansion makes of it.
  class Editorial
    # What each editorial choice takes, in order of preference.
    PREFERENCES = {"app" => %w[lem rdg], "choice" => %w[corr reg expan], "subst" => %w[add], "del" => []}.freeze
    CONTENTS = Set.new(%w[supplied add unclear restore damage sic corr orig reg abbr expan lem rdg]).freeze
    MAX_DEPTH = 256

    def initialize(index, budget:)
      @index = index
      @copies = CopyExpansion.new(index, budget: budget)
    end

    # The effective child elements, in order, each marked as reached.
    def children(element)
      result = []
      stack = [element_children(element).reverse]
      until stack.empty?
        child = stack.last.pop
        next stack.pop if child.nil?

        expanded = @copies.effective(child)
        next unless expanded

        if editorial?(expanded)
          stack << element_children(chosen(expanded)).reverse
        else
          @index.reach(expanded)
          result << expanded
        end
      end
      result
    end

    # The effective children of a name.
    def children_named(element, name)
      children(element).select { |child| child.name == name }
    end

    # The text of an element's <label>, else its @label, or nil for none.
    def label(element)
      label = children_named(element, "label").first
      text = label ? text(label) : XmlReading.attribute(element, "label", element: element)
      text unless text.to_s.empty?
    end

    # The text of the reading kept, its whitespace collapsed, with <lb/> as
    # a space, leaving out the elements +skip+ answers true for.
    def text(element, skip: nil)
      parts = []
      stack = [nodes(element).reverse]
      until stack.empty?
        node = stack.last.pop
        next stack.pop if node.nil?
        next parts << text_value(node, element) if node.is_a?(REXML::Text)
        next unless node.is_a?(REXML::Element)

        expanded = @copies.effective(node)
        next if expanded.nil? || skip&.call(expanded)
        next parts << " " if expanded.name == "lb"

        stack << nodes(editorial?(expanded) ? chosen(expanded) : expanded).reverse
      end
      parts.join.gsub(/\s+/, " ").strip
    end

    private

    def editorial?(element)
      PREFERENCES.key?(element.name) || CONTENTS.include?(element.name)
    end

    # The element whose contents stand for an editorial one, or nil.
    def chosen(element)
      preferences = PREFERENCES[element.name]
      return element unless preferences

      children = element_children(element)
      preferred = preferences.lazy.filter_map { |name| children.find { |child| child.name == name } }.first
      preferred || (children.first if element.name == "choice")
    end

    def nodes(element)
      return [] unless element

      result = []
      element.each { |node| result << node }
      result
    end

    def text_value(node, element)
      node.value
    rescue RuntimeError => error
      raise ParseError.new("MEI text exceeds the entity expansion limits (#{error.message})", element: element)
    end

    def element_children(element)
      return [] unless element

      result = []
      element.each { |child| result << child if child.is_a?(REXML::Element) }
      result
    end
  end
end
