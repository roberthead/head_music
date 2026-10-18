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
        plan.bar_numbers.map { |bar_number| bar_check_after([whole_bar_rest(nil, bar_number), *trailing_spacers(nil, bar_number)], bar_number) }
    end

    # The lines inside a part's \new Dynamics, bar-checked like a voice's.
    def dynamics_lines(part)
      plan.bar_numbers.map { |bar_number| bar_check_after([plan.dynamics_bars(part).fetch(bar_number)], bar_number) }
    end

    private

    attr_reader :plan

    def first_bar_number
      plan.bar_numbers.first
    end

    def last_bar?(bar_number)
      bar_number == plan.bar_numbers.last
    end

    def lead_voice?(voice)
      voice.equal?(plan.flow.voices.first)
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
      CLEF_NAMES.fetch(clef.name_key.to_sym)
    end

    def time_command(meter)
      "\\time #{meter}"
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

    # A bar's marks are written in every voice, as LilyPond expects of \bar
    # and \mark, so each voice reads back with them.
    def bar_line(voice, bar_number, part_index)
      bar = plan.bar(bar_number)
      lead = lead_voice?(voice)
      last = last_bar?(bar_number)
      bar_check_after([
        *BarMarkWriter.opening_tokens(bar, lead: lead),
        *change_commands(voice.part, bar_number),
        staff_change_command(voice, bar_number, part_index),
        *bar_tokens(voice, bar_number),
        *trailing_spacers(voice, bar_number),
        last ? plan.final_barline_marks(voice) : nil,
        *BarMarkWriter.closing_tokens(bar, last: last, lead: lead)
      ], bar_number)
    end

    # A short final bar has no bar check after it, so LilyPond does not
    # expect the bar to be full.
    def bar_check_after(tokens, bar_number)
      tokens << "|" unless short_final_bar?(bar_number)
      tokens.compact.join(" ")
    end

    def short_final_bar?(bar_number)
      last_bar?(bar_number) && plan.short_final_bar_fraction
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
      segments = plan.segments_by_bar(voice)[bar_number]
      return [whole_bar_rest(voice, bar_number)] unless segments

      segments.map { |segment| plan.tokens_by_segment[segment] }
    end

    # Spacers in every voice, so the final barline follows the marks on them.
    def trailing_spacers(voice, bar_number)
      plan.filled_final_bar?(bar_number) ? [plan.trailing_spacers(voice)] : []
    end

    # A voice with nothing in a short final bar rests only as long as the music.
    # The voice's marks in the bar go on its rest, so it keeps them.
    def whole_bar_rest(voice, bar_number)
      marks = plan.timed_marks(voice)
      return short_bar_rest(marks, bar_number) if short_final_bar?(bar_number) || plan.filled_final_bar?(bar_number)

      marks.around(bar_number, 0r, plan.bar_length(bar_number), "R1*#{plan.effective_meter(bar_number)}")
    end

    def short_bar_rest(marks, bar_number)
      from = 0r
      rest = HeadMusic::Notation::DottedDuration.rhythmic_value_for(plan.music_end_fraction) ||
        raise(RenderError, "cannot rest through the short final bar #{bar_number} in LilyPond output: no binary note value spans it")
      rest.tied_chain.map { |link|
        to = from + HeadMusic::Notation::DottedDuration.dotted_unit_fraction(link)
        word = marks.around(bar_number, from, to, "r#{DurationWriter.token(link)}")
        from = to
        word
      }.join(" ")
    end
  end
end
