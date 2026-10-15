module HeadMusic::Notation::MEI
  # A bar as a <measure>: a <staff> for every staff of the score, each with a
  # <layer> for every voice written on it.
  class MeasureWriter
    def initialize(plan)
      @plan = plan
      @event_writer = EventWriter.new(plan)
    end

    def element(bar_number)
      Element.new(
        "measure", ids.container("measure", ids.bar_key(bar_number)), measure_attributes(bar_number),
        plan.staff_entries.map { |entry| staff_element(entry, bar_number) }
      )
    end

    private

    attr_reader :plan, :event_writer

    def ids
      plan.ids
    end

    def measure_attributes(bar_number)
      {
        "n" => bar_number,
        "type" => bar_number.positive? ? nil : "upbeat",
        "metcon" => plan.underfull?(bar_number) ? "false" : nil
      }
    end

    def staff_element(entry, bar_number)
      key = ids.staff_key(bar_number, entry.number)
      layers = plan.layer_voices(entry, bar_number).map { |voice| layer_element(voice, key, bar_number) }
      Element.new("staff", ids.container("staff", key), {"n" => entry.number}, layers)
    end

    def layer_element(voice, staff_key, bar_number)
      number = plan.voice_number(voice)
      items = plan.items(voice, bar_number)
      children = items.empty? ? [event_writer.empty_bar_element(voice, bar_number)] : layer_children(items)
      Element.new("layer", ids.container("layer", "#{staff_key}l#{number}"), {"n" => number}, children)
    end

    def layer_children(items)
      items.flat_map { |item| [*event_writer.grace_elements(item), event_writer.element(item)] }
    end
  end
end
