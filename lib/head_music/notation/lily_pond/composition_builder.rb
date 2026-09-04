# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Replays a Document's voice streams onto a fresh composition.
  #
  # Every placement lands at the voice's next position, so bar checks and
  # key or meter commands are verified against where the music actually
  # is, the way LilyPond verifies them at compile time.
  class CompositionBuilder
    TICKS_PER_WHOLE_NOTE = HeadMusic::Rudiment::Rhythm::PPQN * 4

    attr_reader :document

    def initialize(document)
      @document = document
    end

    def composition
      @composition ||= build
    end

    private

    def build
      streams = document.streams
      raise ParseError, "LilyPond input contains no music" if streams.empty?

      composition = HeadMusic::Content::Composition.new(
        name: document.title, composer: document.composer,
        key_signature: document.first_key_signature, meter: document.first_meter
      )
      streams.each do |stream|
        voice = composition.add_voice(role: stream.role)
        stream.events.each { |event| apply(event, voice) }
      end
      composition
    end

    def apply(event, voice)
      case event.kind
      when :note then voice.place(voice.next_position, event.rhythmic_value, event.pitches)
      when :rest then voice.place(voice.next_position, event.rhythmic_value)
      when :whole_bar_rest then place_whole_bar_rest(event, voice)
      when :bar_check then check_bar(event, voice)
      when :key then apply_change(event, voice, "\\key", :key_signature, :key_signature_at, :change_key_signature)
      when :time then apply_change(event, voice, "\\time", :meter, :meter_at, :change_meter)
      end
    end

    def check_bar(event, voice)
      position = voice.next_position
      return if bar_start?(position)

      raise ParseError.new(
        "Bar check failed at: #{elapsed_fraction(position)} in bar #{position.bar_number}",
        line_number: event.line, snippet: "|"
      )
    end

    # A whole-bar rest is one placement filling the bar it starts; a
    # longer span (R1*2 is two bars in LilyPond) has no single-placement
    # representation yet.
    def place_whole_bar_rest(event, voice)
      position = voice.next_position
      unless bar_start?(position)
        raise unsupported("A whole-bar rest must start a bar", event)
      end

      meter = voice.composition.meter_at(position.bar_number)
      bar_fraction = Rational(meter.top_number, meter.bottom_number)
      rhythmic_value = HeadMusic::Notation::DottedDuration.rhythmic_value_for(event.fraction)
      unless event.fraction == bar_fraction && rhythmic_value
        raise unsupported("Multi-bar rests are not yet supported (#{whole_notes(event.fraction)} whole notes in #{meter})", event)
      end

      voice.place(position, rhythmic_value)
    end

    # A change already in force at its bar is a no-op (the writer repeats
    # each change in every voice); a different explicit value at that bar,
    # or any disagreement with the seed at bar one, is a conflict.
    def apply_change(event, voice, command, attribute, at_reader, changer)
      composition = voice.composition
      value = event.public_send(attribute)
      bar_number = change_bar_number(event, voice, command)
      return if composition.public_send(at_reader, bar_number) == value
      if bar_number == 1 || composition.bars(bar_number).last.public_send(attribute)
        raise ParseError.new("Conflicting #{command} at bar #{bar_number}", line_number: event.line)
      end

      composition.public_send(changer, bar_number, value)
    end

    # Key and meter live on bars, so a change is only representable at a
    # bar's start.
    def change_bar_number(event, voice, command)
      position = voice.next_position
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
