module HeadMusic::Notation::MEI
  # How long a part's music in a measure is, and which measures are short
  # of their meter. A whole-bar rest fills its bar, so a layer beside it
  # that ends short is padded rather than making the bar short, unless the
  # bar is short by its own account: a first measure that says it is an
  # upbeat, or whose every part is shorter than its meter, or a later one
  # with metcon="false".
  module MeasureLength
    module_function

    # How far a part's layers reach in its PartReading::Measure. The first
    # measure is never padded, since whether it is a pickup depends on it.
    def extent(contents, measure)
      return contents.filter_map(&:extent).max if measure.index.zero? || measure.implicit

      contents.filter_map { |content| OpenSpaces.length_of(content, measure.meter) }.max
    end

    def short?(element, index, **where)
      index.positive? && AttributeValues.read(element, "metcon", **where, element: element) == false
    end

    # +extents+ are how far each part's music reaches in the first measure.
    def pickup?(element, meter, extents)
      reach = extents.compact.max
      upbeat = XmlReading.attribute(element, "type", element: element) == "upbeat"
      upbeat || (!reach.nil? && reach < Rational(meter.top_number, meter.bottom_number))
    end
  end
end
