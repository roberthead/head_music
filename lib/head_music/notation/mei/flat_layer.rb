module HeadMusic::Notation::MEI
  # A layer's children in written order, each item after its grace notes, with
  # no containers around them.
  class FlatLayer
    def initialize(plan, event_writer)
      @plan = plan
      @event_writer = event_writer
    end

    def children(_voice, _bar_number, items)
      items.flat_map { |item| [*event_writer.grace_elements(item), event_writer.element(item)] }
    end

    private

    attr_reader :plan, :event_writer
  end
end
