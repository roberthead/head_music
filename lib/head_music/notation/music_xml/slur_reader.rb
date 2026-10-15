require_relative "mark_reader"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads slurs and phrase marks, paired by number within a part in document
  # order. MusicXML has no phrase mark, so a slur with either end on a rest,
  # which a slur cannot sit on, is a phrase; a phrase between two notes comes
  # back as a slur. A slur from a grace note starts on the grace notes before
  # its main note, and one ending on a grace note ends on its main note.
  # Unmatched slurs, and those whose ends fall in different voices, are
  # dropped, as is any the voice refuses.
  class SlurReader < MarkReader
    End = Data.define(:voice, :voice_event, :from_grace)
    Curve = Data.define(:voice, :kind, :from, :to, :from_grace)

    def initialize
      @part = nil
      @open = {}
      @curves = []
    end

    def note(record)
      enter(record.part)
      XmlReading.children(record.element, "notations").each do |notations|
        XmlReading.children(notations, "slur").each { |slur| read(slur, record) }
      end
    end

    def apply(_flow)
      @curves.each do |curve|
        curve.voice.add_span(curve.kind, from: curve.from, to: curve.to, from_grace: curve.from_grace)
      rescue ArgumentError
        next
      end
    end

    private

    def enter(part)
      return if part.equal?(@part)

      @part = part
      @open = {}
    end

    def read(slur, record)
      number = XmlReading.attribute(slur, "number") || "1"
      case XmlReading.attribute(slur, "type")
      when "start" then @open[number] = start_of(record)
      when "stop" then close(@open.delete(number), record)
      end
    end

    # A grace note dropped before a rest or a tie's later link has no grace
    # notes to start from, so its slur starts on what it led to.
    def start_of(record)
      End.new(voice: record.voice, voice_event: record.voice_event, from_grace: record.grace? && !record.grace_index.nil?)
    end

    def close(start, record)
      stop = record.voice_event
      return unless start&.voice_event && stop && start.voice.equal?(record.voice)

      from = start.voice_event
      kind = (from.rest? || stop.rest?) ? :phrase : :slur
      @curves << Curve.new(voice: start.voice, kind: kind, from: from.position, to: stop.position, from_grace: start.from_grace)
    end
  end
end
