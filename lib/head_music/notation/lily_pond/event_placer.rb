# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Places a voice stream's events on its voice. Every event lands at the
  # voice's next position, so bar checks and key or meter commands are
  # verified against where the music actually is, the way LilyPond verifies
  # them at compile time.
  class EventPlacer
    TICKS_PER_WHOLE_NOTE = HeadMusic::Rudiment::Rhythm::PPQN * 4

    def initialize(layout)
      @layout = layout
    end

    def place(event, voice)
      case event.kind
      when :note then place_note(event, voice)
      when :rest then apply_marks(voice.place(voice.next_position, event.rhythmic_value), event)
      when :whole_bar_rest then place_whole_bar_rest(event, voice)
      else apply_marker(event, voice, voice.next_position)
      end
    end

    def check_bar(event, position)
      return if bar_start?(position)

      raise ParseError.new(
        "Bar check failed at: #{elapsed_fraction(position)} in bar #{position.bar_number}",
        line_number: event.line, snippet: "|"
      )
    end

    def place_level(target, position, event)
      level = event.marks.level
      target.place_dynamic(position, level) if level
    rescue ArgumentError => error
      raise ParseError.new(error.message, line_number: event.line)
    end

    private

    attr_reader :layout

    def apply_marker(event, voice, position)
      case event.kind
      when :bar_check then check_bar(event, position)
      when :key then apply_change(event, voice.flow, position, "\\key", :key_signature, :key_signature_at, :change_key_signature)
      when :time then apply_change(event, voice.flow, position, "\\time", :meter, :meter_at, :change_meter)
      when :staff_change then change_staff(event, voice, position)
      when :level then place_level(voice, position, event)
      end
    end

    # Marks are applied where their event was placed, captured before the
    # voice moves on. A rest keeps only a dynamic level.
    def apply_marks(voice_event, event)
      marks = event.marks
      unless voice_event.rest?
        voice_event.articulate(*marks.articulations).embellish(*marks.ornaments)
        voice_event.note_dynamic = marks.note_dynamic if marks.note_dynamic
      end
      place_level(voice_event.voice, voice_event.position, event)
    end

    # A crossing is a staff assignment from a bar onward, so it can only be
    # made at a bar's start, and only to a staff of the voice's own group.
    def change_staff(event, voice, position)
      staff = layout.staff_named(voice.part, event.staff_name)
      unless staff
        raise ParseError.new(%(No staff named "#{event.staff_name}" in this voice's staff group), line_number: event.line)
      end

      voice.cross_to(staff, from: change_bar_number(event, position, "\\change Staff"))
    end

    # What was written between the halves of a tied note takes effect where it
    # was written, in order, so a meter change is in force before the position
    # of anything after it is worked out.
    def place_note(event, voice)
      position = voice.next_position
      event.inner_events.each { |inner| apply_marker(inner.event, voice, position + inner.elapsed) }
      apply_marks(voice.place(position, event.rhythmic_value, event.pitches), event)
    end

    # A whole-bar rest is one voice event filling the bar it starts; a
    # longer span (R1*2 is two bars in LilyPond) has no single voice event
    # representation yet.
    def place_whole_bar_rest(event, voice)
      position = voice.next_position
      unless bar_start?(position)
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

    # A change already in force at its bar is a no-op (the writer repeats
    # each change in every voice); a different explicit value at that bar,
    # or any disagreement with the seed at bar one, is a conflict.
    def apply_change(event, flow, position, command, attribute, at_reader, changer)
      value = event.public_send(attribute)
      bar_number = change_bar_number(event, position, command)
      return if flow.public_send(at_reader, bar_number) == value
      if bar_number == 1 || flow.public_send(:"#{attribute}_change_at", bar_number)
        raise ParseError.new("Conflicting #{command} at bar #{bar_number}", line_number: event.line)
      end

      flow.public_send(changer, bar_number, value)
    end

    # Key and meter live on bars, so a change is only representable at a
    # bar's start.
    def change_bar_number(event, position, command)
      return position.bar_number if bar_start?(position)

      raise unsupported("#{command} in the middle of a bar is not supported", event)
    end

    def bar_start?(position)
      position.count == 1 && position.tick.zero?
    end

    def whole_notes(fraction)
      (fraction.denominator == 1) ? fraction.numerator : fraction
    end

    def elapsed_fraction(position)
      meter = position.meter
      Rational(position.count - 1, meter.bottom_number) + Rational(position.tick, TICKS_PER_WHOLE_NOTE)
    end

    def unsupported(message, event)
      UnsupportedFeatureError.new(message, line_number: event.line)
    end
  end
end
