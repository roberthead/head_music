module HeadMusic::Notation::MEI
  # The control events of dynamics, ornaments, and spans. Ornaments and note
  # dynamics point at their note; slurs and phrases at the notes they join.
  # Dynamic levels and hairpins sit at a beat, on the staff and layer of
  # their voice, or a part's on its top staff and no layer.
  class MarkingEvents
    ORNAMENTS = {
      "trill" => ["trill", nil],
      "mordent" => ["mordent", "lower"],
      "inverted_mordent" => ["mordent", "upper"],
      "turn" => ["turn", nil]
    }.freeze

    HAIRPIN_FORMS = {crescendo: "cres", diminuendo: "dim"}.freeze

    # The part or voice a level or hairpin belongs to.
    Owner = Data.define(:key, :part, :voice) do
      def voices
        voice ? [voice] : part.voices
      end
    end

    attr_reader :controls

    def initialize(plan)
      @plan = plan
      @controls = placed.each_with_index.sort_by { |(position, element), index| [element.bar_number, position, index] }
        .map { |(_, element), _| element }
    end

    private

    attr_reader :plan

    def ids
      plan.ids
    end

    def flow
      plan.flow
    end

    # Each control with the position it is ordered by in its bar.
    def placed
      flow.parts.flat_map do |part|
        part_owner = Owner.new(ids.owner_key(plan.part_number(part)), part, nil)
        [
          *timed(part, part_owner),
          *part.voices.flat_map { |voice| timed(voice, Owner.new(voice_key(voice), part, voice)) + attached(voice) }
        ]
      end
    end

    def voice_key(voice)
      ids.owner_key(plan.part_number(voice.part), plan.voice_number(voice))
    end

    def timed(owner, mark_owner)
      levels = owner.dynamic_events.map { |event| level(event, mark_owner) }
      hairpins = owner.spans.select(&:hairpin?).map { |span| hairpin(span, mark_owner) }
      levels + hairpins
    end

    def level(event, owner)
      position = event.position
      element = Element.new(
        "dynam", ids.container("dynam", "#{owner.key}-#{ids.position_key(position)}"),
        timed_attributes(position, owner), [], event.name_key
      )
      [position, BarElement.new(position.bar_number, element)]
    end

    def hairpin(span, owner)
      from = span.from
      attributes = {
        "form" => HAIRPIN_FORMS.fetch(span.kind),
        **timed_attributes(from, owner),
        "tstamp2" => Tstamp.tstamp2(flow, from, span.to, owner.voices)
      }
      element = Element.new("hairpin", ids.container("hairpin", "#{owner.key}-#{ids.position_key(from)}"), attributes)
      [from, BarElement.new(from.bar_number, element)]
    end

    def timed_attributes(position, owner)
      {
        "tstamp" => Tstamp.beat(flow, position, owner.voices),
        "staff" => owner.voice ? plan.staff_number(owner.voice, position.bar_number) : plan.top_staff_number(owner.part),
        "layer" => owner.voice && plan.voice_number(owner.voice)
      }
    end

    def attached(voice)
      key = voice_key(voice)
      events = voice.note_events.flat_map { |note_event| note_marks(note_event, key) }
      events + voice.spans.select(&:curve?).map { |span| curve(voice, span, key) }
    end

    def note_marks(note_event, owner_key)
      first = plan.items_of(note_event).first
      event_key = "#{owner_key}-#{ids.position_key(note_event.position)}"
      elements = note_event.ornaments.map { |ornament| ornament_element(ornament, event_key, first) }
      dynamic = note_event.note_dynamic
      if dynamic
        elements << Element.new("dynam", ids.container("dynam", "#{event_key}-note"), {"startid" => reference(first.id)}, [], dynamic.name_key)
      end
      elements.map { |element| [note_event.position, BarElement.new(first.segment.bar_number, element)] }
    end

    def ornament_element(ornament, event_key, first)
      name, form = ORNAMENTS.fetch(ornament.name_key)
      id = ids.container(name, [event_key, form].compact.join("-"))
      Element.new(name, id, {"startid" => reference(first.id), "form" => form})
    end

    def curve(voice, span, owner_key)
      first = plan.items_of(voice.voice_event_at(span.from)).first
      start_id = span.from_grace? ? plan.grace_id(first, 0) : first.id
      key = "#{owner_key}-#{ids.position_key(span.from)}#{"g" if span.from_grace?}-#{ids.position_key(span.to)}"
      attributes = {"startid" => reference(start_id), "endid" => reference(closing_item(voice.voice_event_at(span.to)).id)}
      [span.from, BarElement.new(first.segment.bar_number, Element.new(span.name_key, ids.container(span.name_key, key), attributes))]
    end

    def closing_item(voice_event)
      items = plan.items_of(voice_event)
      items.each_with_index.find do |_, index|
        HeadMusic::Notation::SpanEnds.closing_piece?(voice_event, first: index.zero?, last: index == items.length - 1)
      end.first
    end

    def reference(id)
      "##{id}"
    end
  end

  MeasureWriter.control_sources << MarkingEvents
end
