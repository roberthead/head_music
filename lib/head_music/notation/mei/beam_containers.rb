module HeadMusic::Notation::MEI
  # The <beam>s of a layer's bar, grouped as the MusicXML writer groups them.
  # A beam that cuts across a tuplet cannot nest in the layer, so it becomes
  # a <beamSpan> control event instead.
  class BeamContainers
    LEVELS_BY_DUR = {"8" => 1, "16" => 2, "32" => 3, "64" => 4, "128" => 5, "256" => 6}.freeze

    def initialize(plan, spans)
      @plan = plan
      @spans = spans
    end

    def beams(voice, bar_number, tuplets)
      items = @plan.items(voice, bar_number)
      groups(items, bar_number).filter_map do |group|
        beam = LayerContainers::Container.new("beam", @plan.ids.item_container("beam", items[group.first].id), group.first, group.last, {})
        next beam if tuplets.all? { |tuplet| tuplet.nests_with?(beam) }

        add_span(voice, bar_number, items.values_at(*group))
        nil
      end
    end

    private

    def groups(items, bar_number)
      return [] if items.empty?

      events = items.map { |item| beam_event(item) }
      HeadMusic::Notation::BeamGroups.groups(events, @plan.effective_meter(bar_number)).select { |group| group.length > 1 }
    end

    def add_span(voice, bar_number, members)
      references = members.map { |member| "##{member.id}" }
      attributes = @plan.staff_and_layer(voice, bar_number)
        .merge("startid" => references.first, "endid" => references.last, "plist" => references.join(" "))
      @spans << BarElement.new(bar_number, Element.new("beamSpan", @plan.ids.item_container("beamspan", members.first.id), attributes))
    end

    # Built as the MusicXML writer builds its events, from the same links.
    def beam_event(item)
      link = item.link
      HeadMusic::Notation::BeamGroups::Event.new(
        levels: levels(item),
        onset: link.offset,
        beam_break_before: link.index.zero? ? item.voice_event.beam_break_before : nil
      )
    end

    def levels(item)
      return 0 if item.rest? || item.measure_rest

      LEVELS_BY_DUR.fetch(Durations.dur(item.link.rhythmic_value), 0)
    end
  end
end
