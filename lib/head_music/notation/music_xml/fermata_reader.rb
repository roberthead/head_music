require_relative "mark_reader"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads <fermata> in a note's <notations>, of any shape, as a fermata mark
  # on the note, chord, or rest it was placed as, whole-measure rests
  # included, and from a tie's later link where it is written there. A
  # <fermata> on a barline between bars marks the events of the part's
  # voices that end there. FermataMarks turns the marks of every part into
  # the timeline's fermatas. Grace notes hold no time, so their fermatas are
  # skipped.
  class FermataReader < MarkReader
    def initialize
      @marks = HeadMusic::Notation::FermataMarks.new
    end

    def note(record)
      voice_event = record.voice_event
      return if record.grace? || voice_event.nil? || !fermata?(record.element)

      from = record.continuation? ? link_start(record) : voice_event.position
      @marks.add(voice_event, from: from)
    end

    def barline(record)
      return if record.mid_bar? || !XmlReading.first_child(record.element, "fermata")

      barline = barline_position(record)
      record.part.voices.each do |voice|
        voice_event = voice.voice_events.find { |candidate| candidate.next_position == barline }
        @marks.add(voice_event) if voice_event
      end
    end

    def apply(flow)
      @marks.apply(flow)
    end

    private

    def fermata?(element)
      XmlReading.children(element, "notations").any? { |notations| XmlReading.first_child(notations, "fermata") }
    end

    def link_start(record)
      HeadMusic::Notation::BarSplitter.position_at(record.part.flow, record.bar_number, record.onset)
    end

    # A left barline stands at the start of its bar, any other at its end.
    def barline_position(record)
      flow = record.part.flow
      bar_number = record.bar_number
      left = XmlReading.attribute(record.element, "location") == "left"
      flow.position(left ? bar_number : bar_number + 1, 1, 0)
    end
  end
end
