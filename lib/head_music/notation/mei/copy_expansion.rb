module HeadMusic::Notation::MEI
  # An element with a @copyof stands for a copy of what it names. The copy
  # is cloned, so its elements have no ids in the index and no control can
  # name them, and expanded once, however often it is asked for. A copy
  # within its own copy raises, as does expansion past the budget of
  # elements, or a chain of copies or a copy deeper than Editorial::MAX_DEPTH.
  class CopyExpansion
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

    # The element itself, or the expanded copy it stands for; nil for a copy
    # of something in another file.
    def effective(element)
      return element unless copy_reference(element)

      @copies.fetch(element) { @copies[element] = expand(element) }
    end

    private

    def copy_reference(element)
      XmlReading.attribute(element, "copyof", element: element)
    end

    def element_children(node)
      node.children.grep(REXML::Element)
    end

    # A clone of what the element copies, every copy inside it expanded in
    # turn.
    def expand(element)
      root, chain = replacement(element, nil)
      return unless root

      stack = [[root, chain, 1]]
      until stack.empty?
        node, node_chain, depth = stack.pop
        Editorial.check_depth(depth, "A @copyof nests its copy", element: element)

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
      raise ParseError.new("A chain of @copyof is longer than #{Editorial::MAX_DEPTH}", element: element) if extended.length > Editorial::MAX_DEPTH

      extended
    end

    # REXML's deep_clone recurses, which the depth cap bounds; the budget
    # is charged for every element cloned.
    def deep_clone(element, origin)
      clone = element.deep_clone
      count = 0
      stack = [clone]
      until stack.empty?
        count += 1
        stack.concat(element_children(stack.pop))
      end
      @copied += count
      raise ParseError.new("@copyof expands past #{@budget} elements", element: origin) if @copied > @budget

      clone
    end
  end
end
