require_relative "marking_events"

module HeadMusic::Notation::MEI
  # Reads <trill>, <mordent>, and <turn> as ornaments of the note they start
  # at. A <mordent> of @form "lower", or none, is the mordent, and "upper" the
  # inverted mordent; MEI 4's "norm" and "inv" read the same way. A <turn> of
  # @form "lower" or "inv", which the model has no ornament for, is skipped,
  # as is one at a rest, a grace note, a tie's later link, or only a beat.
  class OrnamentReader < MarkReader
    ORNAMENTS_BY_ELEMENT = MarkingEvents::ORNAMENTS.to_h { |key, (name, form)| [[name, form], key] }.merge(
      ["mordent", nil] => "mordent", ["mordent", "norm"] => "mordent", ["mordent", "inv"] => "inverted_mordent",
      ["turn", "upper"] => "turn", ["turn", "norm"] => "turn"
    ).freeze

    def initialize(anchors)
      super
      @ornamented = []
    end

    def control(record)
      element = record.element
      key = ORNAMENTS_BY_ELEMENT[[element.name, XmlReading.attribute(element, "form", element: element)]]
      voice_event = key && note_event_at(record.start)
      @ornamented << [voice_event, key] if voice_event
    end

    def apply(_flow)
      @ornamented.each { |voice_event, key| voice_event.embellish(key) }
    end

    private

    def note_event_at(anchor)
      event_record = anchor&.record
      return unless event_record&.note? && !event_record.grace? && !event_record.continuation?

      voice_event = anchor.voice_event
      voice_event unless voice_event.nil? || voice_event.rest?
    end
  end
end

HeadMusic::Notation::MEI::MARK_READERS << HeadMusic::Notation::MEI::OrnamentReader
