# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Serializes a part's <part> element, measure by measure: each measure's
  # barlines, attributes, directions and navigation, and every voice's notes.
  class PartWriter
    include HeadMusic::Notation::XmlText

    delegate :bar_numbers, :written_duration, to: :plan

    def initialize(plan)
      @plan = plan
    end

    def lines(part, index)
      [
        %(#{INDENT}<part id="P#{index + 1}">),
        *bar_numbers.flat_map { |bar_number| measure_lines(part, bar_number) },
        "#{INDENT}</part>"
      ]
    end

    private

    attr_reader :plan

    def note_writer
      @note_writer ||= NoteWriter.new(plan)
    end

    def direction_writer
      @direction_writer ||= DirectionWriter.new(plan)
    end

    def attributes_writer
      @attributes_writer ||= AttributesWriter.new(plan)
    end

    def barline_writer
      @barline_writer ||= BarlineWriter.new(plan)
    end

    def navigation_writer
      @navigation_writer ||= NavigationWriter.new(plan)
    end

    def measure_lines(part, bar_number)
      bar = plan.direction_plan(part).bar(bar_number)
      [
        measure_open_tag(bar_number),
        *barline_writer.left_lines(bar_number),
        *attributes_writer.lines(part, bar_number),
        *direction_writer.slot_lines(bar.part_slot),
        *navigation_writer.opening_lines(bar_number),
        *part_content_lines(part, bar),
        *(bar.closing_slot ? direction_writer.slot_lines(bar.closing_slot) : []),
        *navigation_writer.closing_lines(bar_number),
        *barline_writer.right_lines(bar_number),
        "#{INDENT * 2}</measure>"
      ]
    end

    # A <backup> before each voice after the first is how MusicXML writes
    # simultaneous voices in one part. It rewinds by what the previous voice
    # actually wrote, which is less than a measure when it ended mid-bar.
    def part_content_lines(part, bar)
      bar.voice_slots.each_with_index.flat_map do |(voice, slots), index|
        [
          *(index.positive? ? backup_lines(written_duration(part.voices[index - 1], bar.bar_number)) : []),
          *voice_content_lines(part, voice, slots)
        ]
      end
    end

    def backup_lines(duration)
      [
        "#{INDENT * 3}<backup>",
        "#{INDENT * 4}<duration>#{duration}</duration>",
        "#{INDENT * 3}</backup>"
      ]
    end

    # A bar before bar 1 is marked implicit by convention. A partially filled
    # first bar is rejected as a gap in Preflight.
    def measure_open_tag(bar_number)
      implicit = (bar_number < 1) ? %( implicit="yes") : ""
      %(#{INDENT * 2}<measure number="#{bar_number}"#{implicit}>)
    end

    # A voice of nil is a part nobody plays in, which renders as whole-measure
    # rests on its first staff so the chair keeps its line in the score.
    def voice_content_lines(part, voice, slots)
      numbers = {
        voice_number: (part.voices.length > 1) ? part.voices.index(voice) + 1 : nil,
        staff_number: staff_number(part, voice, slots.first.bar_number)
      }
      slots.flat_map do |slot|
        [*direction_writer.slot_lines(slot, **numbers), *slot_content_lines(slot, numbers)]
      end
    end

    def slot_content_lines(slot, numbers)
      case slot.kind
      when :segment then note_writer.lines(slot.segment, **numbers)
      when :whole_measure_rest then note_writer.whole_measure_rest_lines(slot.bar_number, **numbers)
      else []
      end
    end

    # Where a crossing shows up: the same voice reports a different staff on
    # either side of it.
    def staff_number(part, voice, bar_number)
      staves = part.staff_system_at(bar_number).staves
      return nil if staves.length <= 1 || voice.nil?

      index = staves.index { |staff| staff.equal?(voice.staff_at(bar_number)) }
      index && index + 1
    end
  end
end
