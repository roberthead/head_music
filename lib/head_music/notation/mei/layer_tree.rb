module HeadMusic::Notation::MEI
  # A layer's children with its beams and tuplets around them. Grace notes
  # come before their item, inside every container the item is an inner
  # member of.
  class LayerTree
    def initialize(plan, event_writer)
      @plan = plan
      @event_writer = event_writer
      @layer_containers = plan.source(LayerContainers)
    end

    def children(voice, bar_number, items)
      nodes(items, layer_containers.containers(voice, bar_number), 0..(items.length - 1))
    end

    private

    attr_reader :plan, :event_writer, :layer_containers

    # Containers are outermost first, so the first to start at an index is
    # the one to open there.
    def nodes(items, containers, range, graced: false)
      children = []
      index = range.begin
      while index <= range.end
        children.concat(event_writer.grace_elements(items[index])) unless graced && index == range.begin
        outer = containers.find { |container| container.first == index }
        if outer
          inner = containers.select { |container| !container.equal?(outer) && outer.covers?(container) }
          children << Element.new(outer.name, outer.id, outer.attributes, nodes(items, inner, index..outer.last, graced: true))
          index = outer.last + 1
        else
          children << event_writer.element(items[index])
          index += 1
        end
      end
      children
    end
  end
end
