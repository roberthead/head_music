# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # A reader of one kind of marking, which the core runs once the voices are
  # final. A new reader is made for each parse. Each of its hooks is called
  # with every record of its kind, part by part in document order, and then
  # apply(flow) once, after every record of every part, to add what it
  # collected; spans check their anchors when added, so a reader adds
  # nothing before then. A reader only adds markings: it never places a
  # voice event, and skips what it cannot add rather than raising.
  #
  # Each hook does nothing here, so a reader defines only the ones it needs.
  class MarkReader
    # @param record [NoteRecord]
    def note(record)
    end

    # @param record [DirectionRecord]
    def direction(record)
    end

    # @param record [BarlineRecord]
    def barline(record)
    end

    def apply(flow)
    end
  end
end
