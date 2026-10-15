module HeadMusic::Notation::MEI
  # The fixed editorial rule: every walk of the music asks for an element's
  # children here, and gets the one reading of them this reader keeps.
  #
  # - <app> takes its <lem>, or else its first <rdg>.
  # - <choice> takes its <corr>, <reg>, or <expan>, or else its first child.
  # - <subst> takes its <add>.
  # - <supplied>, <add>, <unclear>, <restore>, <damage>, and the other
  #   members of a choice give their contents.
  # - <del> gives nothing.
  #
  # An element with a @copyof stands for a copy of what it names. The copy
  # is cloned, so its elements have no ids in the index and no control can
  # name them, and expanded once, however often it is walked. A copy within
  # its own copy raises, as does expansion past four times the document's
  # elements, or a chain of copies or a copy deeper than MAX_DEPTH.
  class Editorial
    CONTENTS = %w[supplied add unclear restore damage sic corr orig reg abbr expan lem rdg].freeze
    CHOSEN_IN_CHOICE = %w[corr reg expan].freeze
    MAX_DEPTH = 256

    Chain = Data.define(:id, :parent, :length) do
      def include?(other)
        link = self
        while link
          return true if link.id == other

          link = link.parent
        end
        false
      end
    end

    def initialize(index, budget:)
      @index = index
      @budget = budget
      @copied = 0
      @copies = {}.compare_by_identity
    end

    # The effective child elements, in order, each marked as reached.
    def children(element)
      result = []
      stack = [element_children(element).reverse]
      until stack.empty?
        child = stack.last.pop
        next stack.pop if child.nil?

        expanded = effective(child)
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

    # The text of the reading kept, its whitespace collapsed, with <lb/> as
    # a space.
    def text(element)
      parts = []
      stack = [nodes(element).reverse]
      until stack.empty?
        node = stack.last.pop
        next stack.pop if node.nil?
        next parts << text_value(node, element) if node.is_a?(REXML::Text)
        next unless node.is_a?(REXML::Element)

        expanded = effective(node)
        next unless expanded
        next parts << " " if expanded.name == "lb"

        stack << nodes(editorial?(expanded) ? chosen(expanded) : expanded).reverse
      end
      parts.join.gsub(/\s+/, " ").strip
    end

    private

    def editorial?(element)
      %w[app choice subst del].include?(element.name) || CONTENTS.include?(element.name)
    end

    # The element whose contents stand for an editorial one, or nil.
    def chosen(element)
      case element.name
      when "app" then first_named(element, %w[lem]) || first_named(element, %w[rdg])
      when "choice" then first_named(element, CHOSEN_IN_CHOICE) || element_children(element).first
      when "subst" then first_named(element, %w[add])
      when "del" then nil
      else element
      end
    end

    def first_named(element, names)
      element_children(element).find { |child| names.include?(child.name) }
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

    def effective(element)
      return element unless copy_reference(element)

      @copies.fetch(element) { @copies[element] = expand(element) }
    end

    def copy_reference(element)
      XmlReading.attribute(element, "copyof", element: element)
    end

    # A clone of what the element copies, every copy inside it expanded in
    # turn; nil for a copy of something in another file.
    def expand(element)
      root, chain = replacement(element, nil)
      return unless root

      stack = [[root, chain, 1]]
      until stack.empty?
        node, node_chain, depth = stack.pop
        raise ParseError.new("A @copyof nests its copy deeper than #{MAX_DEPTH}", element: element) if depth > MAX_DEPTH

        element_children(node).each do |child|
          entry = expand_child(node, child, node_chain, depth)
          stack << entry if entry
        end
      end
      root
    end

    def expand_child(node, child, chain, depth)
      return [child, chain, depth + 1] unless copy_reference(child)

      copy, copy_chain = replacement(child, chain)
      node.replace_child(child, copy || REXML::Comment.new("an external copy"))
      copy && [copy, copy_chain, depth + 1]
    end

    # Follows a chain of copies of copies to a clone of what it ends at, and
    # answers it with the chain of ids copied to reach it.
    def replacement(element, chain)
      current = element
      reference = copy_reference(current)
      while reference
        target = @index.target(reference, element: element)
        return unless target

        chain = extend_chain(chain, XmlReading.attribute(target, "xml:id", element: target), element)
        current = target
        reference = copy_reference(current)
      end
      [deep_clone(current, element), chain]
    end

    def extend_chain(chain, id, element)
      raise ParseError.new("A @copyof copies itself", element: element) if chain&.include?(id)

      extended = Chain.new(id, chain, chain ? chain.length + 1 : 1)
      raise ParseError.new("A chain of @copyof is longer than #{MAX_DEPTH}", element: element) if extended.length > MAX_DEPTH

      extended
    end

    # REXML's deep_clone recurses, which the depth cap bounds; the budget
    # is charged for every element cloned.
    def deep_clone(element, origin)
      clone = element.deep_clone
      count = 0
      stack = [clone]
      until stack.empty?
        node = stack.pop
        count += 1
        node.each { |child| stack << child if child.is_a?(REXML::Element) }
      end
      @copied += count
      raise ParseError.new("@copyof expands past #{@budget} elements", element: origin) if @copied > @budget

      clone
    end
  end
end
