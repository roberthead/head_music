require_relative "xml_text"

# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Renders a flow as a score-partwise MusicXML 4.0 document, assembled down to
  # the measure; AttributesWriter serializes a measure's attributes and
  # NoteWriter its notes. Whole-flow problems raise before any assembly, so #to_s
  # only ever returns a complete document.
  class Writer
    include XmlText

    attr_reader :flow, :work_title, :movement_number, :transposed, :arranger

    delegate :bar_numbers, :segments_by_bar, :written_duration, to: :plan

    def initialize(flow, work_title: nil, movement_number: nil, transposed: false, arranger: nil)
      @flow = flow
      @work_title = work_title
      @movement_number = movement_number
      @transposed = transposed
      @arranger = arranger
    end

    def to_s
      Preflight.check!(flow)
      plan
      document_lines.join("\n") + "\n"
    end

    private

    # The computed rendering facts. Built here — before assembly — so an
    # unmappable key or duration raises before any output is produced.
    def plan
      @plan ||= RenderPlan.new(flow, transposed: transposed)
    end

    def note_writer
      @note_writer ||= NoteWriter.new(plan)
    end

    def attributes_writer
      @attributes_writer ||= AttributesWriter.new(plan)
    end

    def document_lines
      [
        %(<?xml version="1.0" encoding="UTF-8"?>),
        %(<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">),
        %(<score-partwise version="4.0">),
        *work_lines,
        *movement_lines,
        *identification_lines,
        *part_list_lines,
        *part_lines,
        "</score-partwise>"
      ]
    end

    def work_lines
      [
        "#{INDENT}<work>",
        "#{INDENT * 2}<work-title>#{escape(work_title || flow.name)}</work-title>",
        "#{INDENT}</work>"
      ]
    end

    # A movement titles itself only where a work titles the whole; a document
    # standing alone would otherwise say the same name twice.
    def movement_lines
      [
        movement_number && "#{INDENT}<movement-number>#{escape(movement_number.to_s)}</movement-number>",
        work_title && "#{INDENT}<movement-title>#{escape(flow.name)}</movement-title>"
      ].compact
    end

    def identification_lines
      [
        "#{INDENT}<identification>",
        flow.composer && %(#{INDENT * 2}<creator type="composer">#{escape(flow.composer)}</creator>),
        arranger && %(#{INDENT * 2}<creator type="arranger">#{escape(arranger)}</creator>),
        "#{INDENT * 2}<encoding>",
        "#{INDENT * 3}<software>head_music #{HeadMusic::VERSION}</software>",
        "#{INDENT * 2}</encoding>",
        "#{INDENT}</identification>"
      ].compact
    end

    # One <score-part> per part, not per voice. A part holding one voice renders
    # exactly as it always did, which keeps existing documents unchanged.
    def part_list_lines
      score_part_lines = flow.parts.each_with_index.flat_map do |part, index|
        [
          %(#{INDENT * 2}<score-part id="P#{index + 1}">),
          "#{INDENT * 3}<part-name>#{escape(part_name(part, index))}</part-name>",
          "#{INDENT * 2}</score-part>"
        ]
      end
      ["#{INDENT}<part-list>", *score_part_lines, "#{INDENT}</part-list>"]
    end

    # A voice's role names the part only where the part holds a single voice, so
    # that one voice's role does not stand for several.
    def part_name(part, index)
      part.player&.name ||
        part.instrument&.name ||
        (part.voices.one? ? part.voices.first.role : nil) ||
        "Voice #{index + 1}"
    end

    def part_lines
      flow.parts.each_with_index.flat_map do |part, index|
        [
          %(#{INDENT}<part id="P#{index + 1}">),
          *bar_numbers.flat_map { |bar_number| measure_lines(part, bar_number) },
          "#{INDENT}</part>"
        ]
      end
    end

    def measure_lines(part, bar_number)
      [
        measure_open_tag(bar_number),
        *attributes_writer.lines(part, bar_number),
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
      return note_writer.whole_measure_rest_lines(bar_number, voice_number: voice_number, staff_number: staff_number) unless segments

      segments.flat_map do |segment|
        note_writer.lines(segment, voice_number: voice_number, staff_number: staff_number)
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
