module HeadMusic::Notation::MEI
  # The <section> of measures, each after whatever must change before it.
  #
  # Extension classes are built once per plan with .new(plan):
  # pre_measure_sources answer #pre_measure_elements, every BarElement to
  # write before its bar's measure, bucketed here once. The bar_group, when
  # set, answers #groups, Groups covering the bars in order; a group's element
  # wraps its bars, and a group without one leaves them unwrapped.
  class SectionWriter
    Group = Data.define(:element, :bar_numbers)

    class << self
      attr_accessor :bar_group

      def pre_measure_sources
        @pre_measure_sources ||= []
      end
    end

    def initialize(plan)
      @plan = plan
      @measure_writer = MeasureWriter.new(plan)
      @pre_measure_by_bar = self.class.pre_measure_sources
        .flat_map { |source_class| plan.source(source_class).pre_measure_elements.to_a }
        .group_by(&:bar_number)
    end

    def element
      Element.new("section", plan.ids.container("section"), {}, groups.flat_map { |group| group_children(group) })
    end

    private

    attr_reader :plan, :measure_writer, :pre_measure_by_bar

    def groups
      bar_group = self.class.bar_group
      bar_group ? plan.source(bar_group).groups : [Group.new(nil, plan.bar_numbers.to_a)]
    end

    def group_children(group)
      children = group.bar_numbers.flat_map do |bar_number|
        [*pre_measure_by_bar.fetch(bar_number, []).map(&:element), measure_writer.element(bar_number)]
      end
      group.element ? [group.element.with(children: children)] : children
    end
  end
end
