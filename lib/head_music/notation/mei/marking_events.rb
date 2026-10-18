module HeadMusic::Notation::MEI
  # The control events of dynamics, ornaments, and spans, in bar order.
  # Dynamic levels and hairpins sit at a beat, on the staff and layer of
  # their voice, or a part's on its top staff and no layer; AttachedMarks
  # gives those that point at notes.
  class MarkingEvents
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
      @attached = AttachedMarks.new(plan)
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
          *part.voices.flat_map { |voice| voice_marks(voice, part) }
        ]
      end
    end

    def voice_marks(voice, part)
      key = ids.owner_key(plan.part_number(part), plan.voice_number(voice))
      timed(voice, Owner.new(key, part, voice)) + @attached.placed(voice, key)
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
  end

  MeasureWriter.control_sources << MarkingEvents
end
