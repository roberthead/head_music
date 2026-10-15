module HeadMusic::Notation::MEI
  # Reads <slur> and <phrase> control events, and @slur i/t paired by number
  # within a voice. An end named by id is that event; one placed only by
  # beats is the one note that starts there, and none where several do. A
  # curve from a grace note starts on the grace notes before its main note,
  # and one ending on a grace note ends on its main note. A curve whose ends
  # fall in different voices is dropped, as is any the voice refuses, such
  # as a slur on a rest.
  class SlurReader < MarkReader
    CURVES = %w[slur phrase].freeze
    TOKEN = /\A([imt])([1-6]?)\z/

    End = Data.define(:voice, :voice_event, :from_grace)
    Curve = Data.define(:kind, :from, :to)

    def initialize(anchors)
      super
      @open = {}.compare_by_identity
      @curves = []
    end

    def event(record)
      return unless record.voice

      open = (@open[record.voice] ||= {})
      tokens(record).sort_by { |type, _| (type == "t") ? 0 : 1 }.each do |type, number|
        case type
        when "i" then open[number] = end_of(record)
        when "t" then close(:slur, open.delete(number), end_of(record))
        end
      end
    end

    def control(record)
      name = record.element.name
      return unless CURVES.include?(name)

      close(name.to_sym, control_end(record, record.start, "startid"), control_end(record, record.finish, "endid"))
    end

    def apply(_flow)
      @curves.each do |curve|
        curve.from.voice.add_span(curve.kind, from: curve.from.voice_event.position, to: curve.to.voice_event.position, from_grace: curve.from.from_grace)
      rescue ArgumentError
        next
      end
    end

    private

    def tokens(record)
      value = XmlReading.attribute(record.element, "slur", measure: record.measure, element: record.element)
      value.to_s.split.filter_map { |token| token.match(TOKEN)&.captures }
    end

    # A grace note dropped before a rest has no voice event, so no end.
    def end_of(record)
      record&.voice_event && End.new(voice: record.voice, voice_event: record.voice_event, from_grace: record.grace?)
    end

    def control_end(record, anchor, reference)
      return unless anchor
      return end_of(anchor.record) if XmlReading.attribute(record.element, reference, measure: record.measure, element: record.element)

      notes = anchors.notes_starting_at(anchor)
      end_of(notes.first) if notes.one?
    end

    def close(kind, from, to)
      return unless from && to && from.voice.equal?(to.voice)

      @curves << Curve.new(kind: kind, from: from, to: to)
    end
  end
end

HeadMusic::Notation::MEI::MARK_READERS << HeadMusic::Notation::MEI::SlurReader
