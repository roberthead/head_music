# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Renders a HeadMusic::Content::Flow as a complete LilyPond
  # document string: a \version line, a \header carrying the flow's
  # identity, and a \score with one staff per voice in absolute pitch mode,
  # one line per bar with a trailing bar check.
  #
  # Whole-flow problems (no voices, positional gaps, barline-crossing
  # notes, unmappable keys, durations, or alterations) raise before any
  # assembly, so #to_s only ever returns a complete document.
  class Writer
    LILYPOND_VERSION = "2.24.0"
    INDENT = "  "

    attr_reader :flow

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
        %(#{INDENT}title = "#{StringText.escape(flow.name)}"),
        flow.composer && %(#{INDENT}composer = "#{StringText.escape(flow.composer)}"),
        "}"
      ].compact
    end

    def score_lines
      [
        "\\score {",
        "#{INDENT}<<",
        *flow.parts.each_with_index.flat_map { |part, index| part_lines(part, index) },
        "#{INDENT}>>",
        "#{INDENT}\\layout { }",
        "}"
      ]
    end

    # A part on one staff renders exactly as a voice used to, which is what
    # keeps every existing document byte-identical. A part on several renders
    # a braced or bracketed group, one \\new Staff per staff, each carrying the
    # voices that begin on it.
    def part_lines(part, part_index)
      return part.voices.flat_map { |voice| staff_lines(voice) } if part.staff_system.length == 1

      [
        "#{INDENT * 2}#{group_open(part)}",
        *part.staff_system.staves.each_with_index.flat_map { |staff, staff_index|
          grouped_staff_lines(part, part_index, staff, staff_index)
        },
        "#{INDENT * 2}>>"
      ]
    end

    def group_open(part)
      (part.staff_system.bracket == :bracket) ? "\\new StaffGroup <<" : "\\new PianoStaff <<"
    end

    def grouped_staff_lines(part, part_index, staff, staff_index)
      voices = part.voices.select { |voice| voice.staff.equal?(staff) }
      [
        %(#{INDENT * 3}\\new Staff = "#{staff_id(part_index, staff_index)}" <<),
        *voices_or_silence(part, part_index, staff, voices).map { |line| INDENT * 4 + line },
        "#{INDENT * 3}>>"
      ]
    end

    # A staff nobody begins on still has to appear, or the group loses a line
    # of the system. It carries a rest-filled voice so the bars line up.
    def voices_or_silence(part, part_index, staff, voices)
      return [silent_staff_voice(staff)] if voices.empty?

      voices.flat_map { |voice| voice_lines(voice, part_index, staff) }
    end

    def silent_staff_voice(staff)
      [
        "\\new Voice {",
        *[clef_command_for(staff), *plan.bar_numbers.map { |bar_number| "#{whole_bar_rest(bar_number)} |" }].compact
          .map { |line| INDENT + line },
        "}"
      ].join("\n#{INDENT * 4}")
    end

    def voice_lines(voice, part_index, staff)
      [
        "\\new Voice {",
        *music_lines(voice, part_index: part_index, staff: staff).map { |line| INDENT + line },
        "}"
      ]
    end

    def staff_id(part_index, staff_index)
      "part#{part_index + 1}-staff#{staff_index + 1}"
    end

    def staff_lines(voice)
      [
        "#{INDENT * 2}#{staff_open(voice)}",
        "#{INDENT * 3}\\new Voice {",
        *music_lines(voice).map { |line| INDENT * 4 + line },
        "#{INDENT * 3}}",
        "#{INDENT * 2}}"
      ]
    end

    def staff_open(voice)
      return "\\new Staff {" unless voice.role

      %(\\new Staff \\with { instrumentName = "#{StringText.escape(voice.role)}" } {)
    end

    def music_lines(voice, part_index: nil, staff: nil)
      [
        "\\clef #{clef_name(voice, staff)}",
        plan.first_measure_key,
        time_command(plan.first_measure_meter),
        *plan.bar_numbers.map { |bar_number| bar_line(voice, bar_number, part_index: part_index) }
      ]
    end

    # An authored clef is the source of truth; the selector is the fallback for
    # a part whose staves were never authored -- an ABC import, a bare
    # counterpoint exercise. It reads a *voice's* pitch range, which is why the
    # fallback lives here rather than on the staff.
    def clef_name(voice, staff = nil)
      clef = staff&.clef_at(plan.bar_numbers.first) || HeadMusic::Notation::ClefSelector.for(voice)
      clef_word(clef)
    end

    def clef_command_for(staff)
      clef = staff.clef_at(plan.bar_numbers.first)
      clef && "\\clef #{clef_word(clef)}"
    end

    def clef_word(clef)
      (clef == HeadMusic::Rudiment::Clef.get(:bass_clef)) ? "bass" : "treble"
    end

    def time_command(meter)
      "\\time #{meter.top_number}/#{meter.bottom_number}"
    end

    # \key is per-staff inside << >>, so a mid-piece change is emitted in
    # every voice's stream; \time propagates score-wide, and the duplicate
    # commands are harmless.
    def bar_line(voice, bar_number, part_index: nil)
      tokens = []
      unless bar_number == plan.bar_numbers.first
        change_key = plan.measure_key_changes[bar_number]
        tokens << change_key if change_key
        change_meter = plan.measure_time_changes[bar_number]
        tokens << time_command(change_meter) if change_meter
      end
      staff_change = staff_change_command(voice, bar_number, part_index)
      tokens << staff_change if staff_change
      tokens.concat(bar_tokens(voice, bar_number))
      tokens.join(" ") + " |"
    end

    # A voice moves between the staves of its own part with \change Staff, at
    # exactly the bars its staff-assignment map holds events for -- which is
    # why the span boundaries and the commands are the same thing.
    def staff_change_command(voice, bar_number, part_index)
      return if part_index.nil?

      staff = voice.staff_assignments[bar_number]
      return if staff.nil? || bar_number == plan.bar_numbers.first

      index = voice.part.staff_system_at(bar_number).staves.index { |candidate| candidate.equal?(staff) }
      index && %(\\change Staff = "#{staff_id(part_index, index)}")
    end

    # A bar with no placements for this voice — a voice that ended early,
    # or an empty voice — fills with a whole-bar rest in the effective meter.
    def bar_tokens(voice, bar_number)
      placements = plan.placements_by_bar(voice)[bar_number]
      return [whole_bar_rest(bar_number)] unless placements

      placements.map { |placement| plan.tokens_by_placement[placement] }
    end

    def whole_bar_rest(bar_number)
      meter = plan.effective_meter(bar_number)
      "R1*#{meter.top_number}/#{meter.bottom_number}"
    end
  end
end
