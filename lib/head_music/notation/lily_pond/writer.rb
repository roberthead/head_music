# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Renders a HeadMusic::Content::Composition as a complete LilyPond
  # document string: a \version line, a \header carrying the composition's
  # identity, and a \score with one staff per voice in absolute pitch mode,
  # one line per bar with a trailing bar check.
  #
  # Whole-composition problems (no voices, positional gaps, barline-crossing
  # notes, unmappable keys, durations, or alterations) raise before any
  # assembly, so #to_s only ever returns a complete document.
  class Writer
    LILYPOND_VERSION = "2.24.0"
    INDENT = "  "

    attr_reader :composition

    def initialize(composition)
      @composition = composition
    end

    def to_s
      Preflight.check!(composition)
      plan
      document_lines.join("\n") + "\n"
    end

    private

    # The computed rendering facts. Built here — before assembly — so an
    # unmappable key or duration raises before any output is produced.
    def plan
      @plan ||= RenderPlan.new(composition)
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
        %(#{INDENT}title = "#{StringText.escape(composition.name)}"),
        composition.composer && %(#{INDENT}composer = "#{StringText.escape(composition.composer)}"),
        "}"
      ].compact
    end

    def score_lines
      [
        "\\score {",
        "#{INDENT}<<",
        *composition.voices.flat_map { |voice| staff_lines(voice) },
        "#{INDENT}>>",
        "#{INDENT}\\layout { }",
        "}"
      ]
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

    def music_lines(voice)
      [
        "\\clef #{clef_name(voice)}",
        plan.first_measure_key,
        time_command(plan.first_measure_meter),
        *plan.bar_numbers.map { |bar_number| bar_line(voice, bar_number) }
      ]
    end

    # The selector only returns the treble or bass clef.
    def clef_name(voice)
      clef = HeadMusic::Notation::ClefSelector.for(voice)
      (clef == HeadMusic::Rudiment::Clef.get(:bass_clef)) ? "bass" : "treble"
    end

    def time_command(meter)
      "\\time #{meter.top_number}/#{meter.bottom_number}"
    end

    # \key is per-staff inside << >>, so a mid-piece change is emitted in
    # every voice's stream; \time propagates score-wide, and the duplicate
    # commands are harmless.
    def bar_line(voice, bar_number)
      tokens = []
      unless bar_number == plan.bar_numbers.first
        change_key = plan.measure_key_changes[bar_number]
        tokens << change_key if change_key
        change_meter = plan.measure_time_changes[bar_number]
        tokens << time_command(change_meter) if change_meter
      end
      tokens.concat(bar_tokens(voice, bar_number))
      tokens.join(" ") + " |"
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
