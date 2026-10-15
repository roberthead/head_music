module HeadMusic::Notation::MEI
  # The <beam> and <tuplet> containers of every layer, as ranges of the
  # layer's items, and the control events that stand in for those a layer
  # cannot hold: a <tupletSpan> for a bracket across a barline, which leaves
  # a hidden <tuplet> in each bar, and a <beamSpan> for a beam that cuts
  # across a tuplet. Beams are grouped as the MusicXML writer groups them.
  class LayerContainers
    Container = Data.define(:name, :id, :first, :last, :attributes) do
      def covers?(other)
        first <= other.first && other.last <= last
      end

      def nests_with?(other)
        last < other.first || other.last < first || covers?(other) || other.covers?(self)
      end
    end

    BEAM_LEVELS_BY_DUR = {"8" => 1, "16" => 2, "32" => 3, "64" => 4, "128" => 5, "256" => 6}.freeze

    attr_reader :spans

    def initialize(plan)
      @plan = plan
      @containers = {}
      @spans = []
      plan.flow.voices.each { |voice| plan_voice(voice) }
    end

    # Outermost first: by first item, then the longer, then a tuplet before
    # a beam over the same items.
    def containers(voice, bar_number)
      @containers.fetch([voice, bar_number], [])
    end

    private

    attr_reader :plan

    def ids
      plan.ids
    end

    def plan_voice(voice)
      tuplets = tuplet_containers(voice)
      plan.bar_numbers.each do |bar_number|
        bar_tuplets = tuplets.fetch(bar_number, [])
        beams = beam_containers(voice, bar_number, bar_tuplets)
        all = (bar_tuplets + beams).sort_by { |container| [container.first, -container.last, (container.name == "tuplet") ? 0 : 1] }
        @containers[[voice, bar_number]] = all unless all.empty?
      end
    end

    def tuplet_containers(voice)
      places = item_places(voice)
      segments = plan.segments_by_bar(voice).values.flatten(1)
      brackets = HeadMusic::Notation::TupletBrackets.for(voice, segments, error_class: RenderError)
      brackets.flat_map { |bracket| bracket_containers(voice, bracket, places) }.group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
    end

    # Each item's bar and index in it, by segment and link index.
    def item_places(voice)
      plan.bar_numbers.each_with_object({}.compare_by_identity) do |bar_number, places|
        plan.items(voice, bar_number).each_with_index do |item, index|
          (places[item.segment] ||= {})[item.link_index] = [bar_number, index]
        end
      end
    end

    def bracket_containers(voice, bracket, places)
      ratio = bracket.ratio
      hidden = bracket.crosses_barline? ? {"bracket.visible" => "false", "num.visible" => "false"} : {}
      attributes = {"num" => ratio.actual, "numbase" => ratio.normal}
      indices = bracket.links.filter_map { |link| places[link.segment]&.fetch(link.index, nil) }
      portions = indices.chunk_while { |one, other| one.first == other.first }.map do |portion|
        bar_number = portion.first.first
        first_item = plan.items(voice, bar_number)[portion.first.last]
        [bar_number, Container.new("tuplet", container_id("tuplet", first_item), portion.first.last, portion.last.last, attributes.merge(hidden))]
      end
      add_tuplet_span(voice, bracket, portions, attributes) if bracket.crosses_barline?
      portions
    end

    def add_tuplet_span(voice, bracket, portions, attributes)
      first_bar, first = portions.first
      last_bar, last = portions.last
      start = plan.items(voice, first_bar)[first.first]
      finish = plan.items(voice, last_bar)[last.last]
      span = Element.new(
        "tupletSpan", container_id("tupletspan", start),
        attributes.merge(staff_and_layer(voice, first_bar), "startid" => "##{start.id}", "endid" => "##{finish.id}")
      )
      spans << BarElement.new(first_bar, span)
    end

    def beam_containers(voice, bar_number, tuplets)
      items = plan.items(voice, bar_number)
      return [] if items.empty?

      events = items.map { |item| beam_event(item) }
      groups = HeadMusic::Notation::BeamGroups.groups(events, plan.effective_meter(bar_number)).select { |group| group.length > 1 }
      groups.filter_map do |group|
        beam = Container.new("beam", container_id("beam", items[group.first]), group.first, group.last, {})
        next beam if tuplets.all? { |tuplet| tuplet.nests_with?(beam) }

        add_beam_span(voice, bar_number, items.values_at(*group))
        nil
      end
    end

    def add_beam_span(voice, bar_number, members)
      span = Element.new(
        "beamSpan", container_id("beamspan", members.first),
        staff_and_layer(voice, bar_number).merge(
          "startid" => "##{members.first.id}", "endid" => "##{members.last.id}",
          "plist" => members.map { |member| "##{member.id}" }.join(" ")
        )
      )
      spans << BarElement.new(bar_number, span)
    end

    # Built as the MusicXML writer builds its events, from the same links.
    def beam_event(item)
      link = item.link
      HeadMusic::Notation::BeamGroups::Event.new(
        levels: beam_levels(item),
        onset: link.offset,
        beam_break_before: link.index.zero? ? item.voice_event.beam_break_before : nil
      )
    end

    def beam_levels(item)
      return 0 if item.rest? || item.measure_rest

      BEAM_LEVELS_BY_DUR.fetch(Durations.dur(item.link.rhythmic_value), 0)
    end

    def staff_and_layer(voice, bar_number)
      {"staff" => plan.staff_number(voice, bar_number), "layer" => plan.voice_number(voice)}
    end

    def container_id(kind, item)
      ids.container(kind, item.id.delete_prefix("#{ids.mdiv}-"))
    end
  end
end
