module HeadMusic::Notation::MEI
  # A bar as a <measure>: a <staff> for every staff of the score, each with a
  # <layer> for every voice written on it, then the bar's control events.
  #
  # Extension classes are built once per plan with .new(plan):
  # attribute_sources answer #measure_attributes(bar_number), a Hash merged
  # into the measure's attributes, and control_sources answer #controls, every
  # BarElement they place in any bar, bucketed here once. The layer_builder is
  # built with .new(plan, event_writer) and answers
  # #children(voice, bar_number, items), the elements of the layer.
  class MeasureWriter
    class << self
      attr_writer :layer_builder

      def layer_builder
        @layer_builder ||= LayerTree
      end

      def attribute_sources
        @attribute_sources ||= []
      end

      def control_sources
        @control_sources ||= []
      end
    end

    def initialize(plan)
      @plan = plan
      @event_writer = EventWriter.new(plan)
      @layer_builder = self.class.layer_builder.new(plan, event_writer)
      @attribute_sources = self.class.attribute_sources.map { |source_class| plan.source(source_class) }
      @controls_by_bar = self.class.control_sources
        .flat_map { |source_class| plan.source(source_class).controls.to_a }
        .group_by(&:bar_number)
    end

    def element(bar_number)
      Element.new(
        "measure", ids.container("measure", ids.bar_key(bar_number)), measure_attributes(bar_number),
        [
          *plan.staff_entries.map { |entry| staff_element(entry, bar_number) },
          *controls_by_bar.fetch(bar_number, []).map(&:element)
        ]
      )
    end

    private

    attr_reader :plan, :event_writer, :layer_builder, :attribute_sources, :controls_by_bar

    def ids
      plan.ids
    end

    def measure_attributes(bar_number)
      own = {
        "n" => bar_number,
        "type" => bar_number.positive? ? nil : "upbeat",
        "metcon" => plan.underfull?(bar_number) ? "false" : nil
      }
      attribute_sources.reduce(own) { |merged, source| merged.merge(source.measure_attributes(bar_number)) }
    end

    # A staff no voice is written on in the bar is left bare.
    def staff_element(entry, bar_number)
      key = ids.staff_key(bar_number, entry.number)
      layers = plan.layer_voices(entry, bar_number).map { |voice| layer_element(voice, key, bar_number) }
      Element.new("staff", ids.container("staff", key), {"n" => entry.number}, layers)
    end

    def layer_element(voice, staff_key, bar_number)
      number = plan.voice_number(voice)
      items = plan.items(voice, bar_number)
      children = items.empty? ? [event_writer.empty_bar_element(voice, bar_number)] : layer_builder.children(voice, bar_number, items)
      Element.new("layer", ids.container("layer", "#{staff_key}l#{number}"), {"n" => number}, children)
    end
  end
end
