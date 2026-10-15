require_relative "mark_reader"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads beam breaks where <beam>s differ from the default grouping. Between
  # two beamable notes of a voice in a bar, the writer breaks the primary beam
  # where the later note falls on a beam group's start, so a note gets
  # beam_break_before only where its beam number 1 breaks or joins against
  # that; secondary beams are left to the default.
  class BeamReader < MarkReader
    JOINED = %w[continue end].freeze

    def initialize
      @previous = {}.compare_by_identity
      @breaks = []
    end

    def note(record)
      return if record.grace? || record.chord? || record.voice_event.nil?

      previous = @previous[record.voice]
      @previous[record.voice] = record
      return if record.continuation? || !beamed_pair?(previous, record)

      joined = JOINED.include?(primary_beam(record))
      @breaks << [record.voice_event, !joined] if joined == group_start?(record)
    end

    def apply(_flow)
      @breaks.each { |voice_event, value| voice_event.beam_break_before = value }
    end

    private

    def beamed_pair?(previous, record)
      previous && previous.bar_number == record.bar_number &&
        previous.voice_event.next_position == record.voice_event.position &&
        beamable?(previous) && beamable?(record)
    end

    def beamable?(record)
      !record.voice_event.rest? && RenderPlan::BEAM_LEVELS_BY_TYPE.key?(XmlReading.text(record.element, "type"))
    end

    def primary_beam(record)
      beam = XmlReading.children(record.element, "beam").find { |element| (XmlReading.attribute(element, "number") || "1") == "1" }
      XmlReading.text(beam)
    end

    def group_start?(record)
      unit = record.part.flow.meter_at(record.bar_number).beam_group_unit
      (record.onset % HeadMusic::Notation::DottedDuration.dotted_unit_fraction(unit)).zero?
    end
  end
end
