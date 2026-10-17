module HeadMusic::Notation::MEI
  # A reader of one kind of marking, which the core runs once the voices are
  # final. A new reader is made for each parse, with the ControlAnchors of
  # the score. Each of its hooks is called with every record of its kind in
  # document order, and then apply(flow) once, after every record, to add
  # what it collected; spans check their anchors when added, so a reader
  # adds nothing before then. A reader only adds markings: it never places a
  # voice event, never reads the id index, and skips what it cannot add
  # rather than raising. It reads an element's children and text through
  # its anchors, so that the editorial rule holds.
  #
  # Each hook does nothing here, so a reader defines only the ones it needs.
  # A reader registers itself as it loads:
  #
  #   HeadMusic::Notation::MEI::MARK_READERS << HeadMusic::Notation::MEI::SlurReader
  class MarkReader
    def initialize(anchors)
      @anchors = anchors
    end

    # @param record [EventRecord]
    def event(record)
    end

    # @param record [ControlRecord]
    def control(record)
    end

    # @param record [MeasureRecord]
    def measure(record)
    end

    def apply(flow)
    end

    # The i, m, and t of @beam and @slur, each with its optional number.
    LINK_TOKEN = /\A([imt])([1-6]?)\z/

    private

    attr_reader :anchors

    def attribute_of(record, name)
      XmlReading.attribute(record.element, name, measure: record.measure, element: record.element)
    end

    # Each of the record's @beam or @slur tokens as its letter and number.
    def link_tokens(record, name)
      attribute_of(record, name).to_s.split.filter_map { |token| token.match(LINK_TOKEN)&.captures }
    end
  end
end
