# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Renders a flow as a complete LilyPond document, assembled down to the \new
  # Voice block; VoiceWriter serializes what goes inside it. Whole-flow problems
  # raise before any assembly, so #to_s only ever returns a complete document.
  class Writer
    LILYPOND_VERSION = "2.24.0"
    INDENT = "  "

    attr_reader :flow, :transposed, :arranger

    delegate :name, :composer, :parts, to: :flow, private: true

    # The name a grouped staff is declared with, and that a \change Staff
    # command refers back to.
    def self.staff_id(part_index, staff_index)
      "part#{part_index + 1}-staff#{staff_index + 1}"
    end

    def initialize(flow, transposed: false, arranger: nil)
      @flow = flow
      @transposed = transposed
      @arranger = arranger
    end

    def to_s
      Preflight.check!(flow)
      plan
      document_lines.join("\n") + "\n"
    end

    # The \score block alone, checked and planned as a whole document would be:
    # a book shares one \version and one \header across several of these.
    def score_block(piece: nil)
      Preflight.check!(flow)
      plan
      score_lines(piece: piece)
    end

    private

    # The computed rendering facts. Built here — before assembly — so an
    # unmappable key or duration raises before any output is produced.
    def plan
      @plan ||= RenderPlan.new(flow, transposed: transposed)
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
        arranger && %(#{INDENT}arranger = "#{StringText.escape(arranger)}"),
        "}"
      ].compact
    end

    def score_lines(piece: nil)
      [
        "\\score {",
        "#{INDENT}<<",
        *parts.each_with_index.flat_map { |part, index| part_lines(part, index) },
        "#{INDENT}>>",
        *piece_lines(piece),
        "#{INDENT}\\layout { }",
        "}"
      ]
    end

    # Absent from a document holding one score, where the \header title says it.
    def piece_lines(piece)
      return [] unless piece

      [
        "#{INDENT}\\header {",
        %(#{INDENT * 2}piece = "#{StringText.escape(piece)}"),
        "#{INDENT}}"
      ]
    end

    # A part on one staff holding one voice renders exactly as a voice used to,
    # which is what keeps every existing document byte-identical.
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

    # A grouped staff carries no instrument name, so each voice is named for
    # its role instead, where the reader can find it again.
    def grouped_staff_lines(part, part_index, staff, staff_index)
      voices = part.voices.select { |voice| voice.staff.equal?(staff) }
      voices_blocks = voices.map do |voice|
        voice_block(voice_writer.lines(voice, part_index: part_index, staff: staff), name: voice.role)
      end
      voices_blocks = [voice_block(voice_writer.silent_lines(staff, part: part))] if voices_blocks.empty?
      staff_block(%(\\new Staff = "#{Writer.staff_id(part_index, staff_index)}" <<), voices_blocks, ">>")
    end

    def single_staff_lines(part)
      staff = part.staff_system.first_staff
      case part.voices.length
      when 0 then staff_block(staff_open(part_name(part), "{"), [voice_block(voice_writer.silent_lines(staff, part: part))], "}")
      when 1 then staff_block(staff_open(part.voices.first.role, "{"), [voice_block(voice_writer.lines(part.voices.first, staff: staff))], "}")
      else staff_block(staff_open(part_name(part), "<<"), part.voices.map { |voice| voice_block(voice_writer.lines(voice, staff: staff)) }, ">>")
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

    def staff_block(opening, voice_blocks, closer)
      [
        "#{INDENT * 2}#{opening}",
        *voice_blocks.flatten.map { |line| INDENT * 3 + line },
        "#{INDENT * 2}#{closer}"
      ]
    end

    def voice_block(lines, name: nil)
      opener = name ? %(\\new Voice = "#{StringText.escape(name)}" {) : "\\new Voice {"
      [opener, *lines.map { |line| INDENT + line }, "}"]
    end
  end
end
