module HeadMusic::Notation::MEI
  # Every xml:id of one document, gathered before the walk so that a
  # @copyof can point forward, and the elements the walk reached through the
  # editorial rule, so that a reference into a rejected reading is told from
  # one that names nothing.
  #
  # A reference is an id with or without its "#". One with a file part, as
  # other.mei#n1, points outside the document, and resolves to nil, as does
  # one into an element the walk never reached; the control naming it is
  # skipped. One that names no element raises.
  class IdIndex
    def initialize
      @elements = {}
      @reached = {}.compare_by_identity
    end

    def register(id, element, **where)
      raise ParseError.new(%(The xml:id "#{id[0, 64]}" is used twice), element: element, **where) if @elements.key?(id)

      @elements[id] = element
    end

    def element(id)
      @elements[id]
    end

    def reach(element)
      @reached[element] = true
    end

    def reached?(element)
      @reached.key?(element)
    end

    def external?(reference)
      reference.to_s.strip.index("#").to_i.positive?
    end

    # The element a reference names, without regard to the editorial rule.
    # Nil for a reference into another file.
    def target(reference, **where)
      return if external?(reference)

      id = reference.to_s.strip.delete_prefix("#")
      @elements.fetch(id) do
        raise ParseError.new(%(The reference "#{id[0, 64]}" names no element), **where)
      end
    end

    # The element a control's reference names, or nil where the control is
    # skipped.
    def resolve(reference, **where)
      element = target(reference, **where)
      element if element && reached?(element)
    end
  end
end
