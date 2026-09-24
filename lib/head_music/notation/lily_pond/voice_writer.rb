# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # The lines inside a \new Voice block. Writer decides which staves and voices
  # exist; this decides what each one says.
  class VoiceWriter
    # By LilyPond's name. The octave clefs carry characters LilyPond only
    # accepts inside quotes.
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

    # \transposition names the sounding pitch of a written middle C.
    MIDDLE_C = "C4"

    def initialize(plan)
      @plan = plan
    end

    def lines(voice, part_index: nil, staff: nil)
      opening_lines(clef_name(voice, staff), voice.part) +
        plan.bar_numbers.map { |bar_number| bar_line(voice, bar_number, part_index) }
    end

    # A staff nobody is written on still has to appear, or a tacet part loses
    # its line in the score. Its rest-filled voice opens like any other so the
    # key and time print and the bars line up.
    def silent_lines(staff, part: nil)
      opening_lines(clef_name(nil, staff), part) +
        plan.bar_numbers.map { |bar_number| "#{whole_bar_rest(bar_number)} |" }
    end

    private

    attr_reader :plan

    def first_bar_number
      plan.bar_numbers.first
    end

    def opening_lines(clef_name, part)
      [
        "\\clef #{clef_name}",
        *transposition_line(part),
        plan.first_measure_key(part),
        time_command(plan.first_measure_meter)
      ]
    end

    # The selector is the fallback for a part whose staves were never authored.
    # It reads a *voice's* pitch range, which is why the fallback lives here
    # rather than on the staff.
    def clef_name(voice, staff)
      clef = staff&.clef_at(first_bar_number) || HeadMusic::Notation::ClefSelector.for(voice)
      clef_word(clef)
    end

    def clef_word(clef)
      CLEF_NAMES.fetch(clef.name_key.to_sym)
    end

    def time_command(meter)
      "\\time #{meter.top_number}/#{meter.bottom_number}"
    end

    # What the written pitches sound like. A part carries this rather than a
    # \transpose wrapper, which would move notes that are already written.
    def transposition_line(part)
      return [] unless plan.transposed?

      instrument = part&.instrument_at(first_bar_number)
      return [] unless instrument&.transposing?

      sounding = HeadMusic::Content::Layout::Transposition.for(instrument).sounding(MIDDLE_C)
      ["\\transposition #{PitchWriter.token(sounding)}"]
    end

    def bar_line(voice, bar_number, part_index)
      tokens = [
        *change_commands(voice.part, bar_number),
        staff_change_command(voice, bar_number, part_index),
        *bar_tokens(voice, bar_number)
      ]
      "#{tokens.compact.join(" ")} |"
    end

    # \key is per-staff inside << >>, so a mid-piece change is emitted in
    # every voice's stream; \time propagates score-wide, and the duplicate
    # commands are harmless.
    def change_commands(part, bar_number)
      return [] if bar_number == first_bar_number

      meter = plan.measure_time_changes[bar_number]
      [plan.measure_key_changes(part)[bar_number], meter && time_command(meter)].compact
    end

    # Emitted at exactly the bars the voice's staff-assignment map holds events
    # for, so the crossings and the commands are the same thing.
    def staff_change_command(voice, bar_number, part_index)
      staff = voice.staff_assignments[bar_number]
      return if part_index.nil? || staff.nil? || bar_number == first_bar_number

      index = voice.part.staff_system_at(bar_number).staves.index { |candidate| candidate.equal?(staff) }
      index && %(\\change Staff = "#{Writer.staff_id(part_index, index)}")
    end

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
