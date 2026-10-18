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

    # The @tie of a grace note's pitch, by whether a tie stops and starts there.
    GRACE_TIES = {[true, true] => "m", [true, false] => "t", [false, true] => "i"}.freeze

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
      @attribute_sources = sources(self.class.attribute_sources)
      @child_sources = sources(self.class.child_sources)
    end

    def element(item)
      id = item.id
      node = Node.new(kind: :note, id: id, item: item)
      duration = Durations.attributes(item.link.rhythmic_value)
      return decorated(Element.new("mRest", id), node.with(kind: :m_rest)) if item.measure_rest
      return decorated(Element.new("rest", id, duration), node.with(kind: :rest)) if item.rest?

      sounding_element(duration, node, plan.note_ids(item)) { |pitch| item.note_tie(pitch) }
    end

    def grace_elements(item)
      item.graces.each_with_index.map { |grace, index| grace_element(item, grace, index) }
    end

    # What stands in a layer for a bar the voice places nothing in. It is no
    # item, so no extension decorates it.
    def empty_bar_element(voice, bar_number)
      Element.new("mRest", plan.event_id(voice, plan.flow.position(bar_number, 1, 0, 0)))
    end

    private

    attr_reader :plan, :attribute_sources, :child_sources

    def sources(source_classes)
      source_classes.map { |source_class| plan.source(source_class) }
    end

    def grace_element(item, grace, index)
      follower = item.graces[index + 1]&.pitches || item.voice_event.pitches
      id = plan.grace_id(item, index)
      node = Node.new(kind: :note, id: id, item: item, grace: grace, grace_index: index)
      duration = Durations.attributes(grace.rhythmic_value).merge("grace" => grace.slashed? ? "unacc" : "acc")
      sounding_element(duration, node, plan.grace_note_ids(grace, id)) do |pitch|
        GRACE_TIES[[item.tied_from_grace?(index, pitch), grace.tied? && follower.include?(pitch)]]
      end
    end

    # A lone note carries the duration itself; a chord's notes carry only
    # their ties.
    def sounding_element(duration, node, note_ids)
      chord = !note_ids.one?
      notes = note_ids.map do |pitch, id|
        note_element(node.with(id: id, pitch: pitch, chord_member: chord), (chord ? {} : duration).merge("tie" => yield(pitch)))
      end
      chord ? decorated(Element.new("chord", node.id, duration, notes), node.with(kind: :chord)) : notes.first
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
  end
end
