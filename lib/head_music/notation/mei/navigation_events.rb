module HeadMusic::Notation::MEI
  # Rehearsal marks and navigation on the score's top staff: the rehearsal
  # mark, segno, and coda sign where a bar opens, and Fine, To Coda, a D.C. or
  # D.S., and the count of a repeat played more than twice where it closes.
  class NavigationEvents
    def initialize(plan)
      @plan = plan
    end

    def controls
      plan.bar_numbers.flat_map { |bar_number| opening(bar_number) + closing(bar_number) }
    end

    private

    attr_reader :plan

    def opening(bar_number)
      bar = plan.bar(bar_number)
      [
        bar.rehearsal_mark && control(bar_number, "reh", "0", bar.rehearsal_mark),
        bar.segno? && repeat_mark(bar_number, "segno", "0"),
        bar.coda? && repeat_mark(bar_number, "coda", "0")
      ].select { |element| element }
    end

    def closing(bar_number)
      bar = plan.bar(bar_number)
      plays = bar.ends_repeat_after_num_plays
      ending = closing_beat(bar_number)
      [
        bar.fine? && repeat_mark(bar_number, "fine", ending, "Fine"),
        bar.to_coda? && repeat_mark(bar_number, "coda", ending, "To Coda", key: "tocoda"),
        bar.jump && repeat_mark(bar_number, bar.jump.da_capo? ? "daCapo" : "dalSegno", ending, bar.jump.to_s),
        plays && plays > 2 && control(bar_number, "dir", ending, "×#{plays}")
      ].select { |element| element }
    end

    def repeat_mark(bar_number, func, tstamp, text = nil, key: func.downcase)
      control(bar_number, "repeatMark", tstamp, text, key: key, func: func)
    end

    def control(bar_number, name, tstamp, text, key: nil, func: nil)
      id = plan.ids.container(name.downcase, [plan.ids.bar_key(bar_number), key].compact.join("-"))
      attributes = {"func" => func, "tstamp" => tstamp, "staff" => top_staff}
      BarElement.new(bar_number, Element.new(name, id, attributes, [], text))
    end

    def closing_beat(bar_number)
      Decimals.format(plan.effective_meter(bar_number).top_number + 1)
    end

    def top_staff
      plan.staff_entries.first.number
    end
  end

  MeasureWriter.control_sources << NavigationEvents
end
