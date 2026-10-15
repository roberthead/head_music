module HeadMusic::Notation::MEI
  # Reads <dynam>. A level is a dynamic event where it starts, on the voice
  # its @layer names, else on its part, the first at a position winning. An
  # accent such as sfz is the note dynamic of the note it starts at, the
  # first winning; one at a rest, a grace note, or a tie's later link is
  # skipped. Text that names no dynamic, such as "cresc.", is skipped.
  class DynamReader < MarkReader
    Level = Data.define(:owner, :position, :dynamic)

    def initialize(anchors)
      super
      @levels = []
      @accents = []
    end

    def control(record)
      return unless record.element.name == "dynam" && record.start

      dynamic = HeadMusic::Rudiment::Dynamic.get(anchors.text(record.element).strip)
      if dynamic&.level?
        owner = record.voice || record.part
        @levels << Level.new(owner, record.start.position, dynamic) if owner
      elsif dynamic&.accent?
        note_event = accented(record.start.record)
        @accents << [note_event, dynamic] if note_event
      end
    end

    def apply(_flow)
      @levels.each { |level| place(level) }
      @accents.each { |note_event, dynamic| note_event.note_dynamic ||= dynamic.name_key }
    end

    private

    def accented(event_record)
      return unless event_record && !event_record.grace? && !event_record.continuation?

      voice_event = event_record.voice_event
      voice_event unless voice_event.nil? || voice_event.rest?
    end

    def place(level)
      level.owner.place_dynamic(level.position, level.dynamic)
    rescue ArgumentError
      nil
    end
  end
end

HeadMusic::Notation::MEI::MARK_READERS << HeadMusic::Notation::MEI::DynamReader
