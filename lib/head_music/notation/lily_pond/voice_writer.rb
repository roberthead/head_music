# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # The lines inside a \new Voice block: the clef, key, and time the voice
  # opens with, then one line per bar with a trailing bar check. Writer
  # decides which staves and voices exist; this decides what each one says.
  class VoiceWriter
    # Every clef the gem knows, by LilyPond's name for it. The octave clefs
    # carry characters LilyPond only accepts inside quotes.
    CLEF_NAMES = {
      treble_clef: "treble",
      french_violin_clef: "french",
      vocal_tenor_clef: %("treble_8"),
      double_treble_clef: %("treble^8"),
      soprano_clef: "soprano",
      mezzo_soprano_clef: "mezzosoprano",
      alto_clef: "alto",
      tenor_clef: "tenor",
      baritone_c_clef: "baritone",
      baritone_clef: "varbaritone",
      bass_clef: "bass",
      sub_bass_clef: "subbass",
      neutral_clef: "percussion"
    }.freeze

    def initialize(plan)
      @plan = plan
    end

    # @param part_index [Integer, nil] nil for a voice on a single-staff part,
    #   which has no other staff to change to
    def lines(voice, part_index: nil, staff: nil)
      [
        "\\clef #{clef_name(voice, staff)}",
        plan.first_measure_key,
        time_command(plan.first_measure_meter),
        *plan.bar_numbers.map { |bar_number| bar_line(voice, bar_number, part_index) }
      ]
    end

    # A staff nobody is written on still has to appear, or the group loses a
    # line of the system and a tacet part loses its line in the score. It
    # carries a rest-filled voice, opened like any other so the key and time
    # print, so the bars line up.
    def silent_lines(staff)
      [
        "\\clef #{clef_name(nil, staff)}",
        plan.first_measure_key,
        time_command(plan.first_measure_meter),
        *plan.bar_numbers.map { |bar_number| "#{whole_bar_rest(bar_number)} |" }
      ]
    end

    private

    attr_reader :plan

    # An authored clef is the source of truth; the selector is the fallback for
    # a part whose staves were never authored -- an ABC import, a bare
    # counterpoint exercise. It reads a *voice's* pitch range, which is why the
    # fallback lives here rather than on the staff.
    def clef_name(voice, staff)
      clef = staff&.clef_at(plan.bar_numbers.first) || HeadMusic::Notation::ClefSelector.for(voice)
      clef_word(clef)
    end

    def clef_word(clef)
      CLEF_NAMES.fetch(clef.name_key.to_sym)
    end

    def time_command(meter)
      "\\time #{meter.top_number}/#{meter.bottom_number}"
    end

    def bar_line(voice, bar_number, part_index)
      tokens = [
        *change_commands(bar_number),
        staff_change_command(voice, bar_number, part_index),
        *bar_tokens(voice, bar_number)
      ]
      tokens.compact.join(" ") + " |"
    end

    # \key is per-staff inside << >>, so a mid-piece change is emitted in
    # every voice's stream; \time propagates score-wide, and the duplicate
    # commands are harmless.
    def change_commands(bar_number)
      return [] if bar_number == plan.bar_numbers.first

      meter = plan.measure_time_changes[bar_number]
      [plan.measure_key_changes[bar_number], meter && time_command(meter)].compact
    end

    # A voice moves between the staves of its own part with \change Staff, at
    # exactly the bars its staff-assignment map holds events for -- which is
    # why the crossings and the commands are the same thing.
    def staff_change_command(voice, bar_number, part_index)
      return if part_index.nil?

      staff = voice.staff_assignments[bar_number]
      return if staff.nil? || bar_number == plan.bar_numbers.first

      index = voice.part.staff_system_at(bar_number).staves.index { |candidate| candidate.equal?(staff) }
      index && %(\\change Staff = "#{Writer.staff_id(part_index, index)}")
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
