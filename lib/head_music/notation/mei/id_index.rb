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
  #
  # An xml:id used twice raises only where a control's reference names it,
  # since some encoders reuse ids nothing refers to. A @copyof takes the
  # first element with the id.
  #
  # Ids are registered in document order, so the index tells which of two
  # elements comes first.
  class IdIndex
    def initialize
      @elements = {}
      @duplicates = {}
      @reached = {}.compare_by_identity
      @order = {}.compare_by_identity
    end

    def register(id, element)
      if @elements.key?(id)
        @duplicates[id] = true
      else
        @elements[id] = element
        @order[element] = @order.length
      end
    end

    # Whether a registered element comes before another in the document.
    def before?(earlier, later)
      @order.fetch(earlier, @order.length) < @order.fetch(later, -1)
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

    # The element a control's reference names, whether or not the walk
    # reaches it. Nil for a reference into another file.
    def named(reference, **where)
      id = reference.to_s.strip.delete_prefix("#")
      raise ParseError.new(%(The xml:id "#{id[0, 64]}" that a reference names is used twice), **where) if @duplicates.key?(id)

      target(reference, **where)
    end

    # The element a control's reference names, or nil where the control is
    # skipped.
    def resolve(reference, **where)
      element = named(reference, **where)
      element if element && reached?(element)
    end
  end
end
