# Stand-ins for MEI writer extensions, one method per hook, so the specs can
# register them with allow(...).to receive(...) without touching the real
# registries.
module MEIExtensionStubs
  # Answers every hook, with one valid example of what each places.
  class EveryHook
    attr_reader :nodes

    def initialize(plan)
      @plan = plan
      @nodes = []
    end

    def event_attributes(node)
      nodes << node
      (node.kind == :note) ? {"accid.ges" => "n"} : {"label" => node.kind.to_s}
    end

    def event_children(node)
      return [] unless node.kind == :note && !node.grace?

      verse = ids.child(node.id, "verse", 1)
      [element("verse", verse, {"n" => 1}, [element("syl", ids.child(verse, "syl"), {"wordpos" => "i", "con" => "d"}, [], "la")])]
    end

    def measure_attributes(bar_number)
      (bar_number == 2) ? {"right" => "end"} : {}
    end

    def controls
      @plan.bar_numbers.map do |bar_number|
        bar_element(bar_number, element("dynam", ids.container("dynam", "p1v1-#{ids.bar_key(bar_number)}c1"), {"staff" => 1, "tstamp" => "1"}, [], "p"))
      end
    end

    def pre_measure_elements
      [
        bar_element(2, element("scoreDef", ids.container("scoredef", "b2"), {"keysig" => "1s"})),
        bar_element(2, element("staffDef", ids.container("staffdef", "b2s1"), {"n" => 1}))
      ]
    end

    def groups
      group = HeadMusic::Notation::MEI::SectionWriter::Group
      ending = element("ending", ids.container("ending", "b2"), {"n" => "1", "label" => "1."})
      [group.new(nil, [1]), group.new(ending, @plan.bar_numbers.to_a.drop(1))]
    end

    def staff_def_attributes(entry)
      {"trans.diat" => "0", "trans.semi" => -entry.number}
    end

    private

    def ids
      @plan.ids
    end

    def element(name, id, attributes = {}, children = [], text = nil)
      HeadMusic::Notation::MEI::Element.new(name, id, attributes, children, text)
    end

    def bar_element(bar_number, element)
      HeadMusic::Notation::MEI::BarElement.new(bar_number, element)
    end
  end

  # Wraps every layer's events in one beam.
  class BeamedLayer
    def initialize(plan, event_writer)
      @plan = plan
      @event_writer = event_writer
    end

    def children(_voice, bar_number, items)
      events = items.map { |item| @event_writer.element(item) }
      [HeadMusic::Notation::MEI::Element.new("beam", @plan.ids.container("beam", @plan.ids.bar_key(bar_number)), {}, events)]
    end
  end

  def register_every_mei_hook
    mei = HeadMusic::Notation::MEI
    allow(mei::EventWriter).to receive_messages(attribute_sources: [EveryHook], child_sources: [EveryHook])
    allow(mei::MeasureWriter).to receive_messages(attribute_sources: [EveryHook], control_sources: [EveryHook])
    allow(mei::SectionWriter).to receive_messages(pre_measure_sources: [EveryHook], bar_group: EveryHook)
    allow(mei::ScoreDefWriter).to receive(:staff_def_attribute_sources).and_return([EveryHook])
  end
end

RSpec.configure do |config|
  config.include MEIExtensionStubs
end
