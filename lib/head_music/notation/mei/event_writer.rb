module HeadMusic::Notation::MEI
  # The <note>, <chord>, <rest>, and <mRest> elements of the items in a layer,
  # and the grace notes before them.
  #
  # Extension classes registered in attribute_sources and child_sources are
  # built once per plan with .new(plan). Each element is offered to them as a
  # Node: #event_attributes(node) answers a Hash merged into its attributes,
  # and #event_children(node) an Array of Elements appended to its children.
  class EventWriter
    # Kind is :note, :chord, :rest, or :m_rest. A note in a chord is a :note
    # with chord_member true. A grace note or grace chord carries its
    # GraceNote and its index before the item.
    Node = Data.define(:kind, :id, :item, :pitch, :chord_member, :grace, :grace_index) do
      def initialize(kind:, id:, item:, pitch: nil, chord_member: false, grace: nil, grace_index: nil)
        super
      end

      def grace?
        !grace.nil?
      end
    end

    class << self
      def attribute_sources
        @attribute_sources ||= []
      end

      def child_sources
        @child_sources ||= []
      end
    end

    def initialize(plan)
      @plan = plan
      @attribute_sources = self.class.attribute_sources.map { |source_class| plan.source(source_class) }
      @child_sources = self.class.child_sources.map { |source_class| plan.source(source_class) }
    end

    def element(item)
      if item.measure_rest
        decorated(Element.new("mRest", item.id), Node.new(kind: :m_rest, id: item.id, item: item))
      elsif item.rest?
        rest = Element.new("rest", item.id, Durations.attributes(item.link.rhythmic_value))
        decorated(rest, Node.new(kind: :rest, id: item.id, item: item))
      else
        sounding_element(item.link.rhythmic_value, Node.new(kind: :note, id: item.id, item: item), plan.note_ids(item)) do |pitch|
          tie(item, pitch)
        end
      end
    end

    def grace_elements(item)
      graces = item.graces
      graces.each_with_index.map do |grace, index|
        tied_in = (index.positive? && graces[index - 1].tied?) ? graces[index - 1].pitches : []
        follower = graces[index + 1]&.pitches || item.voice_event.pitches
        id = plan.grace_id(item, index)
        node = Node.new(kind: :note, id: id, item: item, grace: grace, grace_index: index)
        sounding_element(grace.rhythmic_value, node, plan.grace_note_ids(grace, id), "grace" => grace.slashed? ? "acc" : "unacc") do |pitch|
          tie_value(tied_in.include?(pitch), grace.tied? && follower.include?(pitch))
        end
      end
    end

    # What stands in a layer for a bar the voice places nothing in. It is no
    # item, so no extension decorates it.
    def empty_bar_element(voice, bar_number)
      Element.new("mRest", plan.event_id(voice, plan.flow.position(bar_number, 1, 0, 0)))
    end

    private

    attr_reader :plan, :attribute_sources, :child_sources

    def sounding_element(rhythmic_value, node, note_ids, extra = {}, &tie)
      duration = Durations.attributes(rhythmic_value).merge(extra)
      if note_ids.one?
        pitch, = note_ids.first
        return note_element(node.with(pitch: pitch), duration.merge("tie" => tie.call(pitch)))
      end

      notes = note_ids.map do |pitch, id|
        note_element(node.with(id: id, pitch: pitch, chord_member: true), {"tie" => tie.call(pitch)})
      end
      decorated(Element.new("chord", node.id, duration, notes), node.with(kind: :chord))
    end

    def note_element(node, attributes)
      pitch = node.pitch
      element = Element.new("note", node.id, {"pname" => pitch.letter_name.to_s.downcase, "oct" => pitch.register}.merge(attributes))
      decorated(element, node)
    end

    def decorated(element, node)
      attributes = attribute_sources.reduce(element.attributes) { |merged, source| merged.merge(source.event_attributes(node)) }
      children = element.children + child_sources.flat_map { |source| source.event_children(node) }
      element.with(attributes: attributes, children: children)
    end

    def tie(item, pitch)
      return item.tie unless tied_from_grace?(item, pitch)

      {nil => "t", "i" => "m"}.fetch(item.tie, item.tie)
    end

    def tied_from_grace?(item, pitch)
      last = item.graces.last
      last&.tied? && last.pitches.include?(pitch)
    end

    def tie_value(stop, start)
      return "m" if stop && start
      return "t" if stop

      "i" if start
    end
  end
end
