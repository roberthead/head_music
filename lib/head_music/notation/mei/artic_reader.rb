require_relative "artic_attributes"

module HeadMusic::Notation::MEI
  # Reads @artic and <artic> onto their note events, a chord tone's onto its
  # chord. A tie's later links, rests, and grace notes are skipped; grace
  # notes take theirs from VoiceAssignment, since a GraceNote is immutable.
  # Values the model has no articulation for, such as "spicc", are skipped.
  class ArticReader < MarkReader
    ARTICULATIONS_BY_VALUE = ArticAttributes::ARTICS.invert.freeze

    # The articulations that elements carry, each read through +editorial+
    # so that the editorial rule holds.
    def self.articulations(elements, editorial)
      values = elements.flat_map do |element|
        [element, *editorial.children_named(element, "artic")].flat_map do |carrier|
          XmlReading.attribute(carrier, "artic", element: carrier).to_s.split
        end
      end
      values.filter_map { |value| ARTICULATIONS_BY_VALUE[value] }.uniq
    end

    def initialize(anchors)
      super
      @articulated = []
    end

    def event(record)
      voice_event = record.markable_event
      return unless voice_event

      keys = self.class.articulations([record.element], anchors)
      @articulated << [voice_event, keys] if keys.any?
    end

    def apply(_flow)
      @articulated.each { |voice_event, keys| voice_event.articulate(*keys) }
    end
  end
end

HeadMusic::Notation::MEI::MARK_READERS << HeadMusic::Notation::MEI::ArticReader
