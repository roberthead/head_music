require_relative "xml_text"

# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Serializes a part's <part> element, measure by measure: each measure's
  # attributes, its directions, and every voice's notes.
  class PartWriter
    include XmlText

    delegate :bar_numbers, :segments_by_bar, :written_duration, to: :plan

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

    def measure_lines(part, bar_number)
      [
        measure_open_tag(bar_number),
        *attributes_writer.lines(part, bar_number),
        *direction_writer.part_lines(part, bar_number),
        *part_content_lines(part, bar_number),
        "#{INDENT * 2}</measure>"
      ]
    end

    # A <backup> before each voice after the first is how MusicXML writes
    # simultaneous voices in one part. It rewinds by what the previous voice
    # actually wrote, which is less than a measure when it ended mid-bar.
    def part_content_lines(part, bar_number)
      return measure_content_lines(part, part.voices.first, bar_number) if part.voices.length <= 1

      part.voices.each_with_index.flat_map do |voice, index|
        [
          *(index.positive? ? backup_lines(written_duration(part.voices[index - 1], bar_number)) : []),
          *measure_content_lines(part, voice, bar_number)
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
    def measure_content_lines(part, voice, bar_number)
      voice_number = (part.voices.length > 1) ? part.voices.index(voice) + 1 : nil
      staff_number = staff_number(part, voice, bar_number)
      segments = voice && segments_by_bar(voice)[bar_number]
      return whole_measure_content_lines(voice, bar_number, voice_number, staff_number) unless segments

      [
        *segments.flat_map do |segment|
          [
            *direction_writer.voice_lines(voice, bar_number, segment, voice_number: voice_number, staff_number: staff_number),
            *note_writer.lines(segment, voice_number: voice_number, staff_number: staff_number)
          ]
        end,
        *direction_writer.trailing_lines(voice, bar_number, voice_number: voice_number, staff_number: staff_number)
      ]
    end

    def whole_measure_content_lines(voice, bar_number, voice_number, staff_number)
      [
        *(voice && direction_writer.voice_rest_lines(voice, bar_number, voice_number: voice_number, staff_number: staff_number)),
        *note_writer.whole_measure_rest_lines(bar_number, voice_number: voice_number, staff_number: staff_number)
      ]
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
