# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Renders a HeadMusic::Content::Flow as a complete LilyPond
  # document string: a \version line, a \header carrying the flow's
  # identity, and a \score with one staff per voice in absolute pitch mode,
  # one line per bar with a trailing bar check.
  #
  # Assembles the document down to the \new Voice block; VoiceWriter
  # serializes what goes inside it.
  #
  # Whole-flow problems (no voices, positional gaps, barline-crossing
  # notes, unmappable keys, durations, or alterations) raise before any
  # assembly, so #to_s only ever returns a complete document.
  class Writer
    LILYPOND_VERSION = "2.24.0"
    INDENT = "  "

    attr_reader :flow

    delegate :name, :composer, :parts, to: :flow, private: true

    # The name a grouped staff is declared with, and that a \change Staff
    # command refers back to.
    def self.staff_id(part_index, staff_index)
      "part#{part_index + 1}-staff#{staff_index + 1}"
    end

    def initialize(flow)
      @flow = flow
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
      @plan ||= RenderPlan.new(flow)
    end

    def voice_writer
      @voice_writer ||= VoiceWriter.new(plan)
    end

    def document_lines
      [
        %(\\version "#{LILYPOND_VERSION}"),
        *header_lines,
        *score_lines
      ]
    end

    def header_lines
      [
        "\\header {",
        %(#{INDENT}title = "#{StringText.escape(name)}"),
        composer && %(#{INDENT}composer = "#{StringText.escape(composer)}"),
        "}"
      ].compact
    end

    def score_lines
      [
        "\\score {",
        "#{INDENT}<<",
        *parts.each_with_index.flat_map { |part, index| part_lines(part, index) },
        "#{INDENT}>>",
        "#{INDENT}\\layout { }",
        "}"
      ]
    end

    # A part on one staff holding one voice renders exactly as a voice used to,
    # which is what keeps every existing document byte-identical. Holding
    # several, it renders one staff with the voices in parallel, as MusicXML
    # renders the same part; holding none, a silent staff, so the chair keeps
    # its line in the score. A part on several staves renders a braced or
    # bracketed group, one \\new Staff per staff, each carrying the voices that
    # begin on it.
    def part_lines(part, part_index)
      return single_staff_lines(part) if part.staff_system.length == 1

      [
        "#{INDENT * 2}#{group_open(part)}",
        *part.staff_system.staves.each_with_index.flat_map { |staff, staff_index|
          grouped_staff_lines(part, part_index, staff, staff_index).map { |line| INDENT + line }
        },
        "#{INDENT * 2}>>"
      ]
    end

    def group_open(part)
      (part.staff_system.bracket == :bracket) ? "\\new StaffGroup <<" : "\\new PianoStaff <<"
    end

    def grouped_staff_lines(part, part_index, staff, staff_index)
      voices = part.voices.select { |voice| voice.staff.equal?(staff) }
      voices_lines = voices.map { |voice| voice_writer.lines(voice, part_index: part_index, staff: staff) }
      voices_lines = [voice_writer.silent_lines(staff)] if voices_lines.empty?
      staff_block(%(\\new Staff = "#{Writer.staff_id(part_index, staff_index)}" <<), voices_lines, ">>")
    end

    def single_staff_lines(part)
      staff = part.staff_system.first_staff
      case part.voices.length
      when 0 then staff_block(staff_open(part_name(part), "{"), [voice_writer.silent_lines(staff)], "}")
      when 1 then staff_block(staff_open(part.voices.first.role, "{"), [voice_writer.lines(part.voices.first, staff: staff)], "}")
      else staff_block(staff_open(part_name(part), "<<"), part.voices.map { |voice| voice_writer.lines(voice, staff: staff) }, ">>")
      end
    end

    # A staff of several voices, or of none, is named for its part rather than
    # for any one voice's role.
    def part_name(part)
      part.player&.name || part.instrument&.name
    end

    def staff_open(name, opener)
      return "\\new Staff #{opener}" unless name

      %(\\new Staff \\with { instrumentName = "#{StringText.escape(name)}" } #{opener})
    end

    # A staff: its opening, one \new Voice block per voice, and its closer.
    def staff_block(opening, voices_lines, closer)
      [
        "#{INDENT * 2}#{opening}",
        *voices_lines.flat_map { |lines| voice_block(lines) }.map { |line| INDENT * 3 + line },
        "#{INDENT * 2}#{closer}"
      ]
    end

    def voice_block(lines)
      ["\\new Voice {", *lines.map { |line| INDENT + line }, "}"]
    end
  end
end
