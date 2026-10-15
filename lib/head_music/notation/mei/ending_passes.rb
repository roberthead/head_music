module HeadMusic::Notation::MEI
  # The passes an <ending> plays on: its @n as "1", "1, 2", or "1 2", or a
  # range such as "1-3"; else the numbers its @label lists; else its place
  # among the endings of its section. A dashed @n defers to the numbers in
  # its @label, since MEI Export writes passes 1 and 3 as n="1-3" with
  # label="1., 3.".
  module EndingPasses
    module_function

    def passes(ending, order, **where)
      where = where.merge(element: ending)
      n = XmlReading.attribute(ending, "n", **where)
      labelled = label_passes(XmlReading.attribute(ending, "label", **where), where)
      return labelled || AttributeValues.pass_range(n, where) if n&.include?("-")

      AttributeValues.pass_list(n, where) || labelled || [order]
    end

    def label_passes(label, where)
      numbers = label.to_s.scan(/\d{1,9}/)
      AttributeValues.passes(numbers, label, where) unless numbers.empty?
    end
  end
end
