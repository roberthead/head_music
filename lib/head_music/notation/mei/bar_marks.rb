module HeadMusic::Notation::MEI
  # Each measure's barlines, and the <ending>s around the bars of each volta.
  # The last bar ends with a final barline unless it is styled otherwise.
  class BarMarks
    RIGHT = {double: "dbl", final: "end", dashed: "dashed", dotted: "dotted"}.freeze

    def initialize(plan)
      @plan = plan
    end

    def measure_attributes(bar_number)
      bar = plan.bar(bar_number)
      {"left" => bar.starts_repeat? ? "rptstart" : nil, "right" => right(bar)}.compact
    end

    def groups
      @groups ||= plan.bar_numbers.slice_when { |bar_number, _| ending_ends?(bar_number) }
        .map { |bar_numbers| SectionWriter::Group.new(ending_element(bar_numbers.first), bar_numbers) }
    end

    private

    attr_reader :plan

    def right(bar)
      return "rptend" if bar.ends_repeat?
      return "end" if bar.barline == :regular && bar.number == plan.bar_numbers.last

      RIGHT[bar.barline]
    end

    def ending_ends?(bar_number)
      bar = plan.bar(bar_number)
      passes = bar.plays_on_passes
      passes != plan.bar(bar_number + 1)&.plays_on_passes || (passes && bar.ends_repeat?)
    end

    # The passes "1, 2" are n="1-2", since @n holds no spaces.
    def ending_element(bar_number)
      passes = plan.bar(bar_number).plays_on_passes
      return unless passes

      Element.new(
        "ending", plan.ids.container("ending", plan.ids.bar_key(bar_number)),
        {"n" => passes.join("-"), "label" => passes.map { |pass| "#{pass}." }.join(", ")}
      )
    end
  end

  MeasureWriter.attribute_sources << BarMarks
  SectionWriter.bar_group = BarMarks
end
