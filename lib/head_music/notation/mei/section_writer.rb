module HeadMusic::Notation::MEI
  # The <section> of measures.
  class SectionWriter
    def initialize(plan)
      @plan = plan
      @measure_writer = MeasureWriter.new(plan)
    end

    def element
      Element.new(
        "section", plan.ids.container("section"), {},
        plan.bar_numbers.map { |bar_number| measure_writer.element(bar_number) }
      )
    end

    private

    attr_reader :plan, :measure_writer
  end
end
