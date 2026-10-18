module HeadMusic::Notation::MEI
  # The control events of a voice that point at notes: ornaments and note
  # dynamics at their note, slurs and phrases at the notes they join. Each
  # comes with the position it is ordered by in its bar.
  class AttachedMarks
    ORNAMENTS = {
      "trill" => ["trill", nil],
      "mordent" => ["mordent", "lower"],
      "inverted_mordent" => ["mordent", "upper"],
      "turn" => ["turn", nil]
    }.freeze

    def initialize(plan)
      @plan = plan
    end

    def placed(voice, owner_key)
      events = voice.note_events.flat_map { |note_event| note_marks(note_event, owner_key) }
      events + voice.spans.select(&:curve?).map { |span| curve(voice, span, owner_key) }
    end

    private

    attr_reader :plan

    def ids
      plan.ids
    end

    def note_marks(note_event, owner_key)
      first = plan.items_of(note_event).first
      event_key = "#{owner_key}-#{ids.position_key(note_event.position)}"
      elements = note_event.ornaments.map { |ornament| ornament_element(ornament, event_key, first) }
      elements << note_dynamic(note_event.note_dynamic, event_key, first) if note_event.note_dynamic
      elements.map { |element| [note_event.position, BarElement.new(first.segment.bar_number, element)] }
    end

    def ornament_element(ornament, event_key, first)
      name, form = ORNAMENTS.fetch(ornament.name_key)
      Element.new(name, ids.container(name, [event_key, form].compact.join("-")), {"startid" => reference(first.id), "form" => form})
    end

    def note_dynamic(dynamic, event_key, first)
      Element.new("dynam", ids.container("dynam", "#{event_key}-note"), {"startid" => reference(first.id)}, [], dynamic.name_key)
    end

    def curve(voice, span, owner_key)
      first = plan.items_of(voice.voice_event_at(span.from)).first
      start_id = span.from_grace? ? plan.grace_id(first, 0) : first.id
      attributes = {"startid" => reference(start_id), "endid" => reference(closing_item(voice.voice_event_at(span.to)).id)}
      element = Element.new(span.name_key, ids.container(span.name_key, curve_key(span, owner_key)), attributes)
      [span.from, BarElement.new(first.segment.bar_number, element)]
    end

    def curve_key(span, owner_key)
      "#{owner_key}-#{ids.position_key(span.from)}#{"g" if span.from_grace?}-#{ids.position_key(span.to)}"
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
end
