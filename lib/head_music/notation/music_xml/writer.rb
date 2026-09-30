require_relative "xml_text"

# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Renders a flow as a score-partwise MusicXML 4.0 document: its header and
  # part list here, and each part's measures in PartWriter. Whole-flow problems
  # raise before any assembly, so #to_s only ever returns a complete document.
  class Writer
    include XmlText

    attr_reader :flow, :work_title, :movement_number, :transposed, :arranger

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

    def part_writer
      @part_writer ||= PartWriter.new(plan)
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
      flow.parts.each_with_index.flat_map { |part, index| part_writer.lines(part, index) }
    end
  end
end
