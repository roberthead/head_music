# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Places a voice stream's events on its voice. Every event lands at the
  # voice's position, so bar checks and key or meter commands are verified
  # against where the music actually is.
  #
  # An \after places its level that far past where the music it wraps
  # starts.
  #
  # Hairpin marks are gathered wherever a voice's marks are read and paired
  # once the voice is placed, by time rather than written order, since the
  # later links of a tied note are placed before the note's own marks.
  class EventPlacer
    SUBTICKS_PER_WHOLE_NOTE = HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE

    delegate :position, to: :spacers
    delegate :check_bar, to: :bar_commands

    def initialize(layout)
      @bar_commands = BarCommands.new(layout)
      @spacers = Spacers.new
      @spans = SpanPairing.new
      @tuplets = PendingTuplets.new
      @bar_marks = BarMarkPlacer.new
      @hairpin_marks = Hash.new { |hash, voice| hash[voice] = HairpinMarks.new }.compare_by_identity
      @marker_marks = {}.compare_by_identity
    end

    def place(event, voice)
      return place_spacer(event, voice) if event.kind == :spacer
      return apply_marker(event, voice, position(voice)) unless event.music?

      spacers.rest(voice)
      case event.kind
      when :note then place_note(event, voice)
      when :rest then apply_marks(voice.place(voice.next_position, event.rhythmic_value), event)
      when :whole_bar_rest then place_whole_bar_rest(event, voice)
      end
      bar_marks.music_placed(voice)
    end

    def finish(flow)
      spacers.finish
      tuplets.bracket
      @written_end = flow.voices.map { |voice| position(voice) }.max
      @hairpin_marks.each do |voice, hairpin_marks|
        hairpin_marks.pair([voice], written_end: @written_end, final_barline: flow.final_barline_position)
      end
      bar_marks.finish(flow)
    end

    # Where the voices' written time ends, trailing spacers included, once
    # they are all placed.
    attr_reader :written_end

    def after_spacer(position, event)
      spacers.after(position, event)
    end

    def place_level(target, position, event)
      level = event.marks.level
      target.place_dynamic(position, level) if level
    rescue ArgumentError => error
      raise ParseError.new(error.message, line_number: event.line)
    end

    private

    attr_reader :bar_commands, :spacers, :spans, :tuplets, :bar_marks

    def shifted(position, event, name)
      subticks = event.fraction * SUBTICKS_PER_WHOLE_NOTE
      unless subticks.denominator == 1
        raise UnsupportedFeatureError.new("#{name} of #{event.fraction} whole notes falls between subticks", line_number: event.line)
      end

      position.advance(subticks: subticks.to_i)
    end

    def place_dynamics(voice, position, event)
      place_level(voice, position, event)
      @hairpin_marks[voice].add(position, event.marks)
    end

    def place_spacer(event, voice)
      place_dynamics(voice, position(voice), event)
      spacers.hold(voice, event)
    end

    def apply_marker(event, voice, position)
      case event.kind
      when *BarCommands::KINDS then bar_commands.apply(event, voice, position)
      when :dynamics then place_marker(voice, position, event)
      when :after then place_dynamics(voice, shifted(position, event, "An \\after"), event)
      when :bar_mark then bar_marks.hold(event, voice, position)
      when :tuplet_start then tuplets.start(voice, position, event.fraction)
      when :tuplet_end then tuplets.stop(voice, position)
      end
    end

    # A <> takes no time, so its slur marks and accent belong to the note
    # that starts where it stands, and are dropped where none does.
    def place_marker(voice, position, event)
      place_dynamics(voice, position, event)
      @marker_marks[voice] = [position, event.marks]
    end

    # Marks are applied where their event was placed, captured before the
    # voice moves on. A rest keeps only its dynamics.
    def apply_marks(voice_event, event)
      apply_marker_marks(voice_event)
      marks = event.marks
      unless voice_event.rest?
        voice_event.articulate(*marks.articulations).embellish(*marks.ornaments)
        voice_event.note_dynamic = marks.note_dynamic if marks.note_dynamic
      end
      place_dynamics(voice_event.voice, voice_event.position, event)
      spans.apply(voice_event, marks.span_marks)
    end

    # What was written between the halves of a tied note takes effect where it
    # was written, in order, so a meter change is in force before the position
    # of anything after it is worked out.
    def apply_marker_marks(voice_event)
      position, marks = @marker_marks.delete(voice_event.voice)
      return unless position == voice_event.position

      voice_event.note_dynamic ||= marks.note_dynamic unless voice_event.rest?
      spans.apply(voice_event, marks.span_marks)
    end

    def place_note(event, voice)
      position = voice.next_position
      event.inner_events.each { |inner| apply_marker(inner.event, voice, position + inner.elapsed) }
      voice_event = voice.place(position, event.rhythmic_value, event.pitches)
      add_graces(voice_event, event.graces)
      apply_marks(voice_event, event)
    end

    def add_graces(voice_event, graces)
      graces.each do |grace|
        voice_event.add_grace_note(
          grace.pitches, grace.rhythmic_value, slashed: grace.slashed, tied: grace.tied, articulations: grace.marks.articulations
        )
      end
    end

    # A whole-bar rest is one voice event filling the bar it starts; a
    # longer span (R1*2 is two bars in LilyPond) has no single voice event
    # representation yet.
    def place_whole_bar_rest(event, voice)
      position = voice.next_position
      unless bar_commands.bar_start?(position)
        raise unsupported("A whole-bar rest must start a bar", event)
      end

      meter = voice.flow.meter_at(position.bar_number)
      bar_fraction = Rational(meter.top_number, meter.bottom_number)
      rhythmic_value = HeadMusic::Notation::DottedDuration.rhythmic_value_for(event.fraction)
      unless event.fraction == bar_fraction && rhythmic_value
        raise unsupported("Multi-bar rests are not yet supported (#{whole_notes(event.fraction)} whole notes in #{meter})", event)
      end

      apply_marks(voice.place(position, rhythmic_value), event)
    end

    def whole_notes(fraction)
      (fraction.denominator == 1) ? fraction.numerator : fraction
    end

    def unsupported(message, event)
      UnsupportedFeatureError.new(message, line_number: event.line)
    end
  end
end
