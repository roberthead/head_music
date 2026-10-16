require_relative "marking_events"

module HeadMusic::Notation::MEI
  # Reads <trill>, <mordent>, and <turn> as ornaments of the note they start
  # at. A <mordent> of @form "lower", or none, is the mordent, and "upper" the
  # inverted mordent; MEI 4's "norm" and "inv" read the same way. A <turn> of
  # @form "lower" or "inv", which the model has no ornament for, is skipped,
  # as is one at a rest, a grace note, a tie's later link, or only a beat.
  #
  # A note's or chord's @ornam reads beside them, by MEI's data.ORNAM.cmn
  # letters: t the trill, m the mordent, M the inverted mordent, and s the
  # turn. Its other letters are skipped.
  class OrnamentReader < MarkReader
    ORNAMENTS_BY_ELEMENT = MarkingEvents::ORNAMENTS.to_h { |key, (name, form)| [[name, form], key] }.merge(
      ["mordent", nil] => "mordent", ["mordent", "norm"] => "mordent", ["mordent", "inv"] => "inverted_mordent",
      ["turn", "upper"] => "turn", ["turn", "norm"] => "turn"
    ).freeze

    ORNAMENTS_BY_LETTER = {"t" => "trill", "m" => "mordent", "M" => "inverted_mordent", "s" => "turn"}.freeze

    def initialize(anchors)
      super
      @ornamented = []
    end

    def event(record)
      voice_event = record.markable_event
      return unless voice_event

      letters = XmlReading.attribute(record.element, "ornam", element: record.element).to_s.split
      letters.filter_map { |letter| ORNAMENTS_BY_LETTER[letter] }.each { |key| @ornamented << [voice_event, key] }
    end

    def control(record)
      element = record.element
      key = ORNAMENTS_BY_ELEMENT[[element.name, XmlReading.attribute(element, "form", element: element)]]
      voice_event = key && record.start&.record&.markable_event
      @ornamented << [voice_event, key] if voice_event
    end

    def apply(_flow)
      @ornamented.each { |voice_event, key| voice_event.embellish(key) }
    end
  end
end

HeadMusic::Notation::MEI::MARK_READERS << HeadMusic::Notation::MEI::OrnamentReader
