module HeadMusic::MIDI
  # Track 0: the sequence name, and the meter, tempos, and key in force at each
  # played bar wherever they differ from the last written, so a jump back over
  # a change restores what was in force there. Each pass through a bar writes
  # its tempo steps, so a jump into a ramp resumes at the tempo sounding there.
  # Times are exact whole notes.
  class ConductorTrack
    MINOR_QUALIFIERS = %i[minor aeolian].freeze
    MAX_PICKUP_DENOMINATOR = 64

    attr_reader :flow, :timeline, :tempo_steps

    def initialize(flow, timeline, tempo_steps = TempoSteps.new(flow))
      @flow = flow
      @timeline = timeline
      @tempo_steps = tempo_steps
    end

    def events
      written = {}
      events = flow.name.to_s.empty? ? [] : [Text.new(0, :sequence_name, flow.name)]
      timeline.spans.each do |span|
        [time_signature(span), *tempos(span), key_signature(span)].each do |event|
          kind = event.class
          next if written[kind] == event.with(tick: 0)

          written[kind] = event.with(tick: 0)
          events << event
        end
        written.delete(TimeSignature) if span.pickup?
      end
      events
    end

    private

    def time_signature(span)
      meter = flow.meter_at(span.bar_number)
      meter = pickup_meter(span, meter) if span.pickup?
      TimeSignature.new(span.start, meter.top_number, meter.bottom_number, TimeSignature.clocks_per_click(meter).to_i)
    end

    # A pickup is a bar of its own wherever a MIDI denominator can count it.
    # Otherwise it takes the flow's meter, which is restated at bar 1.
    def pickup_meter(span, meter)
      denominator = meter.bottom_number.lcm(span.length.denominator)
      return meter unless denominator <= MAX_PICKUP_DENOMINATOR && denominator.to_s(2).count("1") == 1

      HeadMusic::Rudiment::Meter.get("#{(span.length * denominator).to_i}/#{denominator}")
    end

    # A step on the closing barline is the next span's to write, except
    # after the last, where it restores the tempo a fermata held.
    def tempos(span)
      steps = tempo_steps.in_bar(span.bar_number, from: span.window_from)
      steps = steps.reject { |offset, _| offset >= span.window_from + span.length } unless span.equal?(timeline.spans.last)
      steps.map { |offset, microseconds| Tempo.new(span.time_at(offset), microseconds) }
    end

    # A MIDI key signature holds -7..7 fifths, major or minor, so a key beyond
    # is written as its enharmonic, and a mode as major.
    def key_signature(span)
      event = flow.timeline.key_signature_event_at(span.bar_number)
      fifths = event.signature
      fifths -= 12 while fifths > 7
      fifths += 12 while fifths < -7
      KeySignature.new(span.start, fifths, minor?(event.tonal_context))
    end

    def minor?(context)
      context.respond_to?(:qualifier) && MINOR_QUALIFIERS.include?(context.qualifier)
    end
  end
end
